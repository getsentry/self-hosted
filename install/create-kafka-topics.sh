echo "${_group}Creating additional Kafka topics ..."

# NOTE: This step relies on `kafka` being available from the previous `snuba-api bootstrap` step
# XXX(BYK): We cannot use auto.create.topics as Confluence and Apache hates it now (and makes it very hard to enable)
NEEDED_KAFKA_TOPICS="ingest-attachments ingest-transactions ingest-events ingest-replay-recordings profiles"
for topic in $NEEDED_KAFKA_TOPICS; do
  $dcr kafka kafka-topics --create --topic $topic --bootstrap-server kafka:9092
  echo ""
done

echo "${_endgroup}"
