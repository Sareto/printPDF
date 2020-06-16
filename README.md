# printPDF
Biblioteca em delphi FMX para geração de pdf no android


Vídeo explicando a usabilidade

https://www.youtube.com/watch?v=TVedA821_zA&t=22s

ALTERAÇÕES NA VERSÃO
1 – MILIMETROS PARA PIXELS
Padronizado conforme aos geradores de relatórios e o canvas trabalha, ou seja, convertido de milimetros para pixel, facilitando assim 
o controle de linhas.
OBS. Esta alteração possa força-los a redefinir medidas caso estejam usando em algum projeto
Para usar da maneira antiga na function MilimeterToPixel basta atribuir ao valor de saída o mesmo valor do parâmetro de entrada

2 – Função ImpImage
Left e top invertidos.
Alterado para Pixel também

3 – Função ImpVal
Otimizado para a função ImpTexto... desta forma a manutenção fica centralizada em um lugar

4 – ImpBox, ImpLineH, ImpLineV
Aplicado o controle em pixel 

5 – FileNameToUri
Esta função foi encapsulada dentro da propria classe

6 – Constantes de Bordas
Transformada em properties, ao atribuir um valor a mesmaja converter de MM para pixel. Essa alteração possibilita a alteração dos valores por fora da classe;
