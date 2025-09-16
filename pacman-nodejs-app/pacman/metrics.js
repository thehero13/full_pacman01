// metrics.js (simplified, no InstrumentSelector)

const {
  MeterProvider,
  PeriodicExportingMetricReader,
  ConsoleMetricExporter,
} = require('@opentelemetry/sdk-metrics');
const { OTLPMetricExporter } = require('@opentelemetry/exporter-metrics-otlp-http');
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes: SRA } = require('@opentelemetry/semantic-conventions');
const { metrics } = require('@opentelemetry/api');

const resource = new Resource({
  [SRA.SERVICE_NAME]: 'pacman',
  [SRA.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'dev',
});

const provider = new MeterProvider({ resource });

// Export to Splunk OTel Collector
provider.addMetricReader(new PeriodicExportingMetricReader({
  exporter: new OTLPMetricExporter({
    url:
      process.env.OTEL_EXPORTER_OTLP_METRICS_ENDPOINT ||
      'http://splunk-otel-collector-agent.default.svc:4318/v1/metrics',
  }),
  exportIntervalMillis: 60000,
}));

// Optional: console debugging
if (process.env.METRICS_DEBUG === '1') {
  provider.addMetricReader(new PeriodicExportingMetricReader({
    exporter: new ConsoleMetricExporter(),
    exportIntervalMillis: 5000,
  }));
  console.log('[metrics.js] ConsoleMetricExporter enabled (METRICS_DEBUG=1)');
}

metrics.setGlobalMeterProvider(provider);

