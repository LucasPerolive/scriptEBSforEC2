#!/bin/bash

# Solicita o ID da instância EC2
echo "Digite o ID da EC2:"
read INSTANCE_ID

# Obter a lista de discos associados à instância
DISKS=$(aws ec2 describe-instances \
  --instance-id "$INSTANCE_ID" \
  --query "Reservations[].Instances[].BlockDeviceMappings" \
  --output json)

# Verificar se há discos e iterar sobre eles
echo "$DISKS" | jq -c '.[]' | while read -r disk; do
  # Garantir que os campos 'Ebs' e 'DeviceName' existem
  if echo "$disk" | jq -e '.Ebs' > /dev/null && echo "$disk" | jq -e '.DeviceName' > /dev/null; then
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
  else
    echo "Erro: Campos 'Ebs' ou 'DeviceName' não encontrados para um disco."
  fi
done

echo "Configuração concluída!"
