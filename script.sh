#!/bin/bash

# Solicita o ID da instância EC2
echo "Digite o ID da EC2:"
read INSTANCE_ID

# Obter a lista de discos associados à instância
DISKS=$(aws ec2 describe-instances \
  --instance-id "$INSTANCE_ID" \
  --query "Reservations[].Instances[].BlockDeviceMappings" \
  --output json)

# Exibir o JSON retornado (para depuração)
echo "Discos associados à instância: $DISKS"

# Verificar se há discos e iterar sobre eles
echo "$DISKS" | jq -c '.[]' | while read -r disk; do
  # Validar se o campo Ebs existe no JSON
  if echo "$disk" | jq -e '.Ebs' > /dev/null; then
    DEVICE_NAME=$(echo "$disk" | jq -r '.DeviceName // empty')
    DELETE_ON_TERMINATION=$(echo "$disk" | jq -r '.Ebs.DeleteOnTermination // empty')

    if [ -z "$DEVICE_NAME" ]; then
      echo "Erro: 'DeviceName' não encontrado para um disco."
      continue
    fi

    # Verificar se DeleteOnTermination está desabilitado
    if [ "$DELETE_ON_TERMINATION" == "false" ]; then
      echo "Habilitando DeleteOnTermination para o disco: $DEVICE_NAME"

      # Habilitar DeleteOnTermination para o disco atual
      aws ec2 modify-instance-attribute \
        --instance-id "$INSTANCE_ID" \
        --block-device-mappings "[{\"DeviceName\": \"$DEVICE_NAME\", \"Ebs\": {\"DeleteOnTermination\": true}}]"
    else
      echo "O disco $DEVICE_NAME já está com DeleteOnTermination habilitado."
    fi
  else
    echo "Erro: Campo 'Ebs' não encontrado no disco."
  fi
done

echo "Configuração concluída!"
