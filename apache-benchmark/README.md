# Apache Benchmark (ab)

Apache Benchmark is a command-line tool for benchmarking HTTP web servers. It is designed to give you an impression of how your current Apache installation performs.

## Installation

Apache Benchmark can be installed on macOS using Homebrew:

```bash
# Apache Benchmark comes with Apache HTTP Server
brew install httpd

# Or install just the tools
brew install apache-ab
```

## Basic Usage

### Simple Benchmark

```bash
# Basic test with 100 requests and 10 concurrent connections
ab -n 100 -c 10 http://example.com/

# Test specific endpoint
ab -n 1000 -c 50 http://localhost:8080/api/health
```

### Common Options

```bash
# -n: Total number of requests
# -c: Number of concurrent requests
# -t: Time limit for testing (seconds)
# -k: Enable keep-alive
# -H: Add custom headers

ab -n 1000 -c 10 -k http://example.com/
```

## Advanced Usage

### POST Requests

```bash
# POST request with data
ab -n 100 -c 10 -p data.txt -T application/json http://example.com/api/

# POST with inline data
echo '{"key":"value"}' > post_data.txt
ab -n 100 -c 10 -p post_data.txt -T 'application/json' http://example.com/api/
```

### Custom Headers

```bash
# Add authorization header
ab -n 100 -c 10 -H "Authorization: Bearer token123" http://example.com/api/

# Multiple headers
ab -n 100 -c 10 \
   -H "Content-Type: application/json" \
   -H "Authorization: Bearer token123" \
   http://example.com/api/
```

### Authentication

```bash
# Basic authentication
ab -n 100 -c 10 -A username:password http://example.com/

# Digest authentication
ab -n 100 -c 10 -D username:password http://example.com/
```

### Session Management

```bash
# Use cookies
ab -n 100 -c 10 -C session_id=abc123 http://example.com/

# Load cookies from file
ab -n 100 -c 10 -C session_file.txt http://example.com/
```

## Output and Metrics

### Understanding Results

```bash
ab -n 1000 -c 50 http://example.com/
```

Key metrics in the output:
- **Requests per second**: Overall throughput
- **Time per request**: Average response time
- **Transfer rate**: Data transfer speed
- **Connection Times**: min/mean/median/max response times
- **Percentage of requests**: Response time distribution

### Save Results to File

```bash
# Save detailed output
ab -n 1000 -c 50 -g results.tsv http://example.com/

# Save summary to file
ab -n 1000 -c 50 http://example.com/ > benchmark_results.txt
```

## Performance Testing Scenarios

### Load Testing

```bash
# Gradual load increase
ab -n 500 -c 5 http://example.com/   # Light load
ab -n 1000 -c 25 http://example.com/ # Medium load
ab -n 2000 -c 100 http://example.com/ # Heavy load
```

### Stress Testing

```bash
# High concurrency test
ab -n 5000 -c 200 -k http://example.com/

# Time-based stress test (run for 60 seconds)
ab -t 60 -c 100 -k http://example.com/
```

### Endurance Testing

```bash
# Long-running test with keep-alive
ab -n 10000 -c 50 -k -t 300 http://example.com/
```

## Best Practices

### Pre-Testing Checklist

1. **Warm up the server**: Run a small test first
2. **Use keep-alive**: Add `-k` flag for realistic scenarios
3. **Test from different locations**: Network latency matters
4. **Monitor server resources**: CPU, memory, disk I/O during tests

### Realistic Testing

```bash
# Simulate real user behavior with keep-alive
ab -n 2000 -c 50 -k -H "User-Agent: Mozilla/5.0" http://example.com/

# Test with realistic payload sizes
ab -n 1000 -c 25 -p large_payload.json -T application/json http://example.com/api/
```

### Testing Different Endpoints

```bash
# Create a test script for multiple endpoints
#!/bin/bash
endpoints=(
  "http://example.com/"
  "http://example.com/api/users"
  "http://example.com/api/products"
)

for endpoint in "${endpoints[@]}"; do
  echo "Testing: $endpoint"
  ab -n 500 -c 25 -k "$endpoint"
  echo "---"
done
```

## Limitations and Considerations

### Apache Benchmark Limitations

- Single-threaded (limited concurrent connections)
- No JavaScript execution (for modern web apps)
- Limited to HTTP/1.1
- No complex user scenarios

### When to Use Alternatives

For more advanced testing, consider:
- **JMeter**: GUI-based, complex scenarios
- **Artillery**: Modern load testing, JavaScript support
- **K6**: Developer-centric, JavaScript scenarios
- **wrk**: Multi-threaded, higher performance

### Example Alternative Commands

```bash
# Using curl for quick tests
curl -w "@curl-format.txt" -s -o /dev/null http://example.com/

# Using wrk (if available)
wrk -t12 -c400 -d30s http://example.com/
```

## Troubleshooting

### Common Issues

```bash
# Increase system limits if needed
ulimit -n 65536

# Handle "socket: Too many open files" error
echo "net.core.somaxconn = 65536" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### Debug Mode

```bash
# Verbose output for debugging
ab -v 2 -n 10 -c 1 http://example.com/

# Test connectivity first
ab -n 1 -c 1 http://example.com/
```

## Example Scripts

### Quick Demo Script

A simple demonstration script is included:

```bash
./demo.sh [URL]

# Example usage
./demo.sh http://localhost:8080
./demo.sh http://example.com
```

### Automated Benchmark Script

```bash
#!/bin/bash
# benchmark.sh - Automated Apache Benchmark testing

URL=${1:-"http://localhost:8080"}
OUTPUT_DIR="benchmark_results_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$OUTPUT_DIR"

echo "Starting benchmark tests for: $URL"

# Light load test
echo "Running light load test..."
ab -n 500 -c 10 -k "$URL" > "$OUTPUT_DIR/light_load.txt"

# Medium load test
echo "Running medium load test..."
ab -n 1000 -c 50 -k "$URL" > "$OUTPUT_DIR/medium_load.txt"

# Heavy load test
echo "Running heavy load test..."
ab -n 2000 -c 100 -k "$URL" > "$OUTPUT_DIR/heavy_load.txt"

echo "Benchmark completed. Results saved in: $OUTPUT_DIR"
```

### Performance Comparison Script

```bash
#!/bin/bash
# compare.sh - Compare performance between environments

URLS=("http://staging.example.com" "http://production.example.com")
TESTS=(10 25 50 100)

for url in "${URLS[@]}"; do
  echo "Testing: $url"
  for concurrency in "${TESTS[@]}"; do
    echo "Concurrency: $concurrency"
    ab -n 1000 -c "$concurrency" -k "$url" | grep "Requests per second"
  done
  echo "---"
done
```