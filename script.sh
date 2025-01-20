#!/bin/bash

# Solicita o ID da instância EC2
echo "Digite o ID da EC2:"
read INSTANCE_ID

# Obter a lista de discos associados à instância
DISKS=$(aws ec2 describe-instances \
  --instance-id "$INSTANCE_ID" \
  --query "Reservations[].Instances[].BlockDeviceMappings" \
  --output json)

# Filtra os dispositivos que têm DeleteOnTermination = false
DEVICE_NAMES=$(echo "$DISKS" | jq -r '.[][] | select(.Ebs.DeleteOnTermination == false) | .DeviceName')

# Prepara o bloco de mapeamento de dispositivos para alterar a configuração
BLOCK_DEVICE_MAPPING="["

# Para cada dispositivo, cria o mapeamento de modificação
for DEVICE_NAME in $DEVICE_NAMES; do
  BLOCK_DEVICE_MAPPING+="{\"DeviceName\": \"$DEVICE_NAME\", \"Ebs\": {\"DeleteOnTermination\": true}},"
done

# Remove a vírgula extra no final
BLOCK_DEVICE_MAPPING="${BLOCK_DEVICE_MAPPING%,}]"

# Habilitar DeleteOnTermination para os discos filtrados
aws ec2 modify-instance-attribute \
  --instance-id "$INSTANCE_ID" \
  --block-device-mappings "$BLOCK_DEVICE_MAPPING"

echo "Configuração concluída!"
