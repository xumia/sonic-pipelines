# event-collector

> A GitHub App built with [Probot](https://github.com/probot/probot) that Event Collector

## Setup

```sh
# Install dependencies
npm install

# Run the bot
npm start
```

## Docker

```sh
# 1. Build container
docker build -t event-collector .

# 2. Start container
docker run -e APP_ID=<app-id> -e PRIVATE_KEY=<pem-value> event-collector
```

## Contributing

If you have suggestions for how event-collector could be improved, or want to report a bug, open an issue! We'd love all and any contributions.

For more, check out the [Contributing Guide](CONTRIBUTING.md).

## License

[ISC](LICENSE) © 2021 Xuhui Miao <xumia@microsoft.com>
