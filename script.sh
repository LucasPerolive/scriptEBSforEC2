#!/bin/bash

# Substitua pelo ID da sua instância EC2
echo "Digite o ID da EC2:"
read INSTANCE_ID

# Obter a lista de discos associados à instância
DISKS=$(aws ec2 describe-instances \
  --instance-id "$INSTANCE_ID" \
  --query "Reservations[].Instances[].BlockDeviceMappings[?Ebs.DeleteOnTermination==\`false\`]" \
  --output json)

# Verificar se existem discos com DeleteOnTermination desabilitado
if [ "$DISKS" == "[]" ]; then
  echo "Todos os discos já possuem a exclusão automática habilitada."
  exit 0
fi

# Iterar sobre cada disco encontrado
echo "$DISKS" | jq -c '.[]' | while read -r disk; do
  DEVICE_NAME=$(echo "$disk" | jq -r '.DeviceName')

  echo "Habilitando DeleteOnTermination para o disco: $DEVICE_NAME"

  # Habilitar DeleteOnTermination para o disco atual
  aws ec2 modify-instance-attribute \
    --instance-id "$INSTANCE_ID" \
    --block-device-mappings "[{\"DeviceName\": \"$DEVICE_NAME\", \"Ebs\": {\"DeleteOnTermination\": true}}]"
done

echo "Configuração concluída!"

