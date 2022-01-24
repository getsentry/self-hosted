echo "${_group}Creating additional Kafka topics ..."

# NOTE: This step relies on `kafka` being available from the previous `snuba-api bootstrap` step
# XXX(BYK): We cannot use auto.create.topics as Confluence and Apache hates it now (and makes it very hard to enable)
EXISTING_KAFKA_TOPICS=$($dcr kafka kafka-topics --list --bootstrap-server kafka:9092 2>/dev/null)
NEEDED_KAFKA_TOPICS="ingest-attachments ingest-transactions ingest-events"
for topic in $NEEDED_KAFKA_TOPICS; do
  if ! echo "$EXISTING_KAFKA_TOPICS" | grep -wq $topic; then
    $dcr kafka kafka-topics --create --topic $topic --bootstrap-server kafka:9092
    echo ""
  fi
done

echo "${_endgroup}"
