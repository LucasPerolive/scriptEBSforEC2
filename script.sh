#!/bin/bash

# Substitua pelo ID da sua instância EC2
echo "Digite o ID da EC2:"
read INSTANCE_ID

# Obter a lista de discos associados à instância
DISKS=$(aws ec2 describe-instances \
  --instance-id "$INSTANCE_ID" \
  --query "Reservations[].Instances[].BlockDeviceMappings" \
  --output json)

# Verificar se existem discos e iterar sobre eles
echo "$DISKS" | jq -c '.[]' | while read -r disk; do
  DELETE_ON_TERMINATION=$(echo "$disk" | jq -r '.Ebs.DeleteOnTermination')
  DEVICE_NAME=$(echo "$disk" | jq -r '.DeviceName')

  # Verificar se DeleteOnTermination está desabilitado
  if [ "$DELETE_ON_TERMINATION" == "false" ]; then
    echo "Habilitando DeleteOnTermination para o disco: $DEVICE_NAME"

    # Habilitar DeleteOnTermination para o disco atual
    aws ec2 modify-instance-attribute \
      --instance-id "$INSTANCE_ID" \
      --block-device-mappings "[{\"DeviceName\": \"$DEVICE_NAME\", \"Ebs\": {\"DeleteOnTermination\": true}}]"
  fi
done

echo "Configuração concluída!"
