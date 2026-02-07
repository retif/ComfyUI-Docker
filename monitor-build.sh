#!/bin/bash
# Monitor GitHub Actions builds with automatic retry on failure

set -euo pipefail

REPO="retif/ComfyUI-Docker"
WORKFLOW="build-cu130-megapak-pt210.yml"
CHECK_INTERVAL=30  # seconds
MAX_RETRIES=3

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --run-id ID       Monitor specific run ID"
    echo "  --watch           Watch latest run continuously"
    echo "  --retry           Retry on failure (up to $MAX_RETRIES times)"
    echo "  --interval SECS   Check interval in seconds (default: $CHECK_INTERVAL)"
    echo "  -h, --help        Show this help"
    exit 1
}

# Parse arguments
RUN_ID=""
WATCH_MODE=false
AUTO_RETRY=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --run-id)
            RUN_ID="$2"
            shift 2
            ;;
        --watch)
            WATCH_MODE=true
            shift
            ;;
        --retry)
            AUTO_RETRY=true
            shift
            ;;
        --interval)
            CHECK_INTERVAL="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Get latest run if no run ID specified
get_latest_run() {
    gh run list --repo "$REPO" --workflow="$WORKFLOW" --limit 1 --json databaseId,status,conclusion,displayTitle,createdAt \
        | jq -r '.[0] | "\(.databaseId)|\(.status)|\(.conclusion)|\(.displayTitle)|\(.createdAt)"'
}

# Get run status
get_run_status() {
    local run_id=$1
    gh run view "$run_id" --repo "$REPO" --json status,conclusion,displayTitle,createdAt,jobs \
        | jq -r '"\(.status)|\(.conclusion)|\(.displayTitle)|\(.createdAt)"'
}

# Get detailed job info
get_job_details() {
    local run_id=$1
    gh run view "$run_id" --repo "$REPO" --json jobs \
        | jq -r '.jobs[] | "\(.name)|\(.status)|\(.conclusion)|\(.steps[] | select(.conclusion == "failure") | .name)"' 2>/dev/null || echo ""
}

# Trigger new build
trigger_build() {
    echo "🔄 Triggering new build..."
    gh workflow run "$WORKFLOW" --repo "$REPO"
    sleep 5  # Wait for workflow to register
    local new_run_id
    new_run_id=$(get_latest_run | cut -d'|' -f1)
    echo "✅ New build triggered: Run ID $new_run_id"
    echo "$new_run_id"
}

# Monitor a specific run
monitor_run() {
    local run_id=$1
    local retry_count=${2:-0}
    local start_time
    start_time=$(date +%s)

    echo "👀 Monitoring build: Run ID $run_id (Attempt $((retry_count + 1))/$((MAX_RETRIES + 1)))"
    echo "📊 Check interval: ${CHECK_INTERVAL}s"
    echo "🔗 View on GitHub: https://github.com/$REPO/actions/runs/$run_id"
    echo ""

    local prev_status=""
    local prev_steps=""

    while true; do
        local run_info
        run_info=$(get_run_status "$run_id")

        local status conclusion title created_at
        IFS='|' read -r status conclusion title created_at <<< "$run_info"

        # Get current steps
        local current_steps
        current_steps=$(gh run view --job=$(gh run view "$run_id" --repo "$REPO" --json jobs | jq -r '.jobs[0].databaseId') --repo "$REPO" 2>/dev/null | grep -E '^\s+[✓X*-]' || echo "")

        # Only print if status changed or steps updated
        if [[ "$status|$current_steps" != "$prev_status|$prev_steps" ]]; then
            local elapsed=$(($(date +%s) - start_time))
            local elapsed_min=$((elapsed / 60))
            local elapsed_sec=$((elapsed % 60))

            clear
            echo "═══════════════════════════════════════════════════════════"
            echo "📦 ComfyUI Docker Build Monitor"
            echo "═══════════════════════════════════════════════════════════"
            echo "🆔 Run ID:    $run_id"
            echo "📝 Title:     $title"
            echo "⏱️  Elapsed:   ${elapsed_min}m ${elapsed_sec}s"
            echo "📅 Started:   $created_at"
            echo "🔗 URL:       https://github.com/$REPO/actions/runs/$run_id"
            echo "═══════════════════════════════════════════════════════════"
            echo ""

            case $status in
                "queued")
                    echo "⏳ Status: QUEUED"
                    ;;
                "in_progress")
                    echo "⚙️  Status: IN PROGRESS"
                    echo ""
                    echo "Current steps:"
                    echo "$current_steps"
                    ;;
                "completed")
                    case $conclusion in
                        "success")
                            echo "✅ Status: SUCCESS"
                            echo ""
                            echo "🎉 Build completed successfully in ${elapsed_min}m ${elapsed_sec}s!"
                            echo ""
                            echo "📥 Pull the image:"
                            echo "   docker pull ghcr.io/retif/comfyui-boot:cu130-megapak-pt210"
                            return 0
                            ;;
                        "failure")
                            echo "❌ Status: FAILED"
                            echo ""
                            echo "Failed steps:"
                            local failed_info
                            failed_info=$(get_job_details "$run_id")
                            if [[ -n "$failed_info" ]]; then
                                echo "$failed_info" | grep -v '||$' | cut -d'|' -f4 | sort -u | sed 's/^/  - /'
                            fi
                            echo ""

                            if [[ "$AUTO_RETRY" == "true" ]] && [[ $retry_count -lt $MAX_RETRIES ]]; then
                                echo "🔄 Auto-retry enabled. Triggering retry $((retry_count + 2))/$((MAX_RETRIES + 1))..."
                                local new_run_id
                                new_run_id=$(trigger_build)
                                sleep 5
                                monitor_run "$new_run_id" $((retry_count + 1))
                                return $?
                            else
                                if [[ $retry_count -ge $MAX_RETRIES ]]; then
                                    echo "⚠️  Max retries ($MAX_RETRIES) reached. Manual intervention required."
                                fi
                                return 1
                            fi
                            ;;
                        "cancelled")
                            echo "🚫 Status: CANCELLED"
                            return 1
                            ;;
                        *)
                            echo "❓ Status: $conclusion"
                            return 1
                            ;;
                    esac
                    ;;
            esac

            echo ""
            echo "Next check in ${CHECK_INTERVAL}s... (Ctrl+C to stop)"

            prev_status="$status"
            prev_steps="$current_steps"
        fi

        # Check if completed
        if [[ "$status" == "completed" ]]; then
            break
        fi

        sleep "$CHECK_INTERVAL"
    done
}

# Main logic
main() {
    if [[ -z "$RUN_ID" ]]; then
        echo "🔍 Finding latest run..."
        local latest_run
        latest_run=$(get_latest_run)
        RUN_ID=$(echo "$latest_run" | cut -d'|' -f1)

        if [[ -z "$RUN_ID" ]]; then
            echo "❌ No runs found for workflow: $WORKFLOW"
            exit 1
        fi

        echo "📍 Latest run: $RUN_ID"
        echo ""
    fi

    monitor_run "$RUN_ID" 0
}

main
