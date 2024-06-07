#
# IAC 2023/2024 k-means
# 
# Grupo: 8
# Campus: Taguspark
#
# Autores:
# 51948, Iuri Campos
# 103192, Miguel Noronha
# 110645, Duarte Oliveira
#
# Tecnico/ULisboa


# ALGUMA INFORMACAO ADICIONAL PARA CADA GRUPO:
# - A "LED matrix" deve ter um tamanho de 32 x 32
# - O input e' definido na seccao .data. 
# - Abaixo propomos alguns inputs possiveis. Para usar um dos inputs propostos, basta descomentar 
#   esse e comentar os restantes.
# - Encorajamos cada grupo a inventar e experimentar outros inputs.
# - Os vetores points e centroids estao na forma x0, y0, x1, y1, ...


# Variaveis em memoria
.data

#Input A - linha inclinada
#n_points:    .word 9
#points:      .word 0,0, 1,1, 2,2, 3,3, 4,4, 5,5, 6,6, 7,7 8,8

#Input B - Cruz
#n_points:    .word 5
#points:     .word 4,2, 5,1, 5,2, 5,3 6,2

#Input C
#n_points:    .word 23
#points: .word 0,0, 0,1, 0,2, 1,0, 1,1, 1,2, 1,3, 2,0, 2,1, 5,3, 6,2, 6,3, 6,4, 7,2, 7,3, 6,8, 6,9, 7,8, 8,7, 8,8, 8,9, 9,7, 9,8

#Input D
n_points:    .word 30
points:      .word 16, 1, 17, 2, 18, 6, 20, 3, 21, 1, 17, 4, 21, 7, 16, 4, 21, 6, 19, 6, 4, 24, 6, 24, 8, 23, 6, 26, 6, 26, 6, 23, 8, 25, 7, 26, 7, 20, 4, 21, 4, 10, 2, 10, 3, 11, 2, 12, 4, 13, 4, 9, 4, 9, 3, 8, 0, 10, 4, 10


# Valores de centroids e k a usar na 1a parte do projeto:
#centroids:   .word 0,0
#k:           .word 1
 
# Valores de centroids, k e L a usar na 2a parte do prejeto:
centroids:   .word 0,0, 0,0, 0,0
k:           .word 3
L:           .word 10

# Abaixo devem ser declarados o vetor clusters (2a parte) e outras estruturas de dados
# que o grupo considere necessarias para a solucao:
clusters: .word 0, 0, 0, 0, 0, 0, 0, 0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0

# Random configs
seed: .word 1234


#Definicoes de cores a usar no projeto 

colors:      .word 0xff0000, 0x00ff00, 0x0000ff  # Cores dos pontos do cluster 0, 1, 2, etc.

.equ         black      0
.equ         white      0xffffff



# Codigo
 
.text

    # Incializa o ecra a cor branca
    jal initializeScreen
    
    # Chama funcao principal da 1a parte do projeto
    #jal mainSingleCluster

    # Descomentar na 2a parte do projeto:
    jal mainKMeans

    #Termina o programa (chamando chamada sistema)
    li a7, 10
    ecall


### printPoint
# Pinta o ponto (x,y) na LED matrix com a cor passada por argumento
# Nota: a implementacao desta funcao ja' e' fornecida pelos docentes
# E' uma funcao auxiliar que deve ser chamada pelas funcoes seguintes que pintam a LED matrix.
# Argumentos:
# a0: x
# a1: y
# a2: cor

printPoint:
    li a3, LED_MATRIX_0_HEIGHT
    sub a1, a3, a1
    addi a1, a1, -1
    li a3, LED_MATRIX_0_WIDTH
    mul a3, a3, a1
    add a3, a3, a0
    slli a3, a3, 2
    li a0, LED_MATRIX_0_BASE
    add a3, a3, a0   # addr
    sw a2, 0(a3)
    jr ra
    
    
### initializeScreen
# Coloca todos os pontos do ecra a branco
# Argumentos: nenhum
# Retorno: nenhum


initializeScreen:
    li t3, white                # Carrega a cor branca
    la t0, LED_MATRIX_0_BASE    # Endereço base do display LED
    li t1, LED_MATRIX_0_HEIGHT  # Número de linhas do display
    li t2, LED_MATRIX_0_WIDTH   # Número de colunas (assumindo que a largura é conhecida)

loop1:  # Loop por linha do display
    mv t4, t2                   # Inicializa contador de colunas para esta linha
    li t5, 4                    # Tamanho de cada entrada de cor no display (4 bytes por cor)

loop2:  # Loop por coluna dentro de cada linha
    sw t3, 0(t0)                # Escreve a cor branca na posição atual
    add t0, t0, t5             # Avança o endereço para a próxima coluna
    addi t4, t4, -1             # Decrementa o contador de colunas
    bnez t4, loop2              # Continua se ainda houver colunas para processar

    addi t1, t1, -1             # Decrementa o contador de linhas
    bgez t1, loop1              # Repete para a próxima linha se ainda houver linhas
    
    
### cleanScreen
# Limpa todos os pontos do ecra
# Argumentos: nenhum
# Retorno: nenhum

cleanScreen:
    # OPTIMIZATION - Se estiverem menos de 45 pontos impressos, o codigo limpa um a um, se tiver mais de 45
    # chama o initializeScreen que limpa o ecra todo que é mais rapido.
    li a2 white #Adiciona a cor ao argumento a ser utilizado pela funcao printPoint
    lw t0 n_points # Numero dos pontos
    li t3 45 # Numero de pontos para o quala funcao deixa de ser eficiente 
    addi sp sp -4 # Cria espaço na stack para guardar o ra
    sw ra 0(sp) # Guarda o ra para poder chamar o printPoint
    li t5 0 # Inicializa o t5 a 0
    bge t0 t3 initializeScreenCall # Caso o numero de pontos seja superior a 45, ele inicialia o ecra todo
    
    # Precorre o vetor points e apaga-os um a um
    la t1 points # Par de cordendas dos pontos
    loop: 
        lw a0 0(t1) # Carrega a primeira coordenada para o 1º argumento a ser utilizado pelo printPoint
        lw a1 4(t1) # Carrega a segunda coordenada para o 1º argumento a ser utilizado pelo printPoint
        addi t1 t1 8 # Avançar para o proximo ponto, ou seja, avança 8 bytes
        jal printPoint # chama a função printPoint 
        addi t0 t0 -1 # Reduz o numero de pontos a processar
        bnez t0 loop # Volta a correr o loop
    # Faz o load dos dados do vetor centroids e corre o loop de cima com os novos dados
    bnez t5 final # Confirma se o segundo loop já foi corrido, se sim, vai para o final
    la t1 centroids # Carrega o vetor de centroids a apagar
    la t0 k # Carrega a morada do k
    lw t0 0(t0) # Carrega o numero de centroids
    li t5 1 # Variavel para validar que o segundo loop foi corrido
    j loop # volta a correr o loop com os novos dados
    
    
    initializeScreenCall:
        jal initializeScreen
    final:  lw ra 0(sp) # Repoe o ra
            addi sp sp 4 # Repoe o stack point
            jr ra # Retorna ao Ponto de chamada
     
### printClusters
# Pinta os agrupamentos na LED matrix com a cor correspondente.
# Argumentos: nenhum
# Retorno: nenhum

printClusters:
    la t0 points # Vector de pontos
    la t3 clusters # Vetor dos clusters que define a que cluster o ponto pertence
    lw t1 n_points # Numero de pontos no vetor
    la t2 colors # Carregar o vector das cores
    loop_clus:
        beqz t1 end # Verifica se o valor no registo t1 é zero, se for, vai para o end
        lw t5 0(t3) # Carrega o cluster a que o ponto pertence
        slli t5 t5 2 # Multiplica por 4 o index
        add t2 t2 t5 # Avanca o vetor cor para a cor correta
        lw a2 0(t2) # Carrega a cor correcta para o a2
        sub t2 t2 t5 # Volta a colocar o vetor cor no inicio
        lw a0 0(t0) # carregar primeira coordenada
        lw a1 4(t0) # carregar a segunda coordenada
        addi sp sp -4 # Cria espaço na stack para guardar um registo
        sw ra 0(sp) # Guarda o ra na stack para poder chamar a função printPoint sem perde de informacao
        jal printPoint # Chama a funcao printPoint
        lw ra 0(sp) # Repoe o ra
        addi sp sp 4 # Volta a colocar o sp no sitio
        addi t0 t0 8 # avanca 2 posicoes no vector
        addi t3 t3 4 # Avanca 1 posicao no vetor cluster
        addi t1 t1 -1 # Reduz o numero de pontos a processar
        j loop_clus 
    end: jr ra


### printCentroids
# Pinta os centroides na LED matrix
# Nota: deve ser usada a cor preta (black) para todos os centroides
# Argumentos: nenhum
# Retorno: nenhum

printCentroids:
    la t0 centroids # carrega o vector de centroids
    lw t1 k # carrega o numero de centroids
    la t2 colors # carrega o vetor colors
    loop_printcentroid: 
        beqz t1 end_loopcentr # confirma se o k nao e zero
        # lw a2 0(t2) #carrega a  cor para er utilizada pelo printPoint
        li a2 0
        lw a0 0(t0) # carreega a primeira coordenada do centroid
        lw a1 4(t0) # carrega a segunda coordenada do centroid
        addi sp sp -4 # Adiciona espaço na stack para guardar um registo 
        sw ra 0(sp) # Guarda a ra na stack
        jal printPoint # faz o print do centroid
        lw ra 0(sp) # Recupera a ra 
        addi sp sp 4 # Repoe o sp 
        #addi t2 t2 1 # avanca para a proxima cor
        addi t0 t0 8 # Avanca 2 posicoes no vector
        addi t1 t1 -1 # diminui o k
        j loop_printcentroid
    
    end_loopcentr: jr ra
    

### calculateCentroids
# Calcula os k centroides, a partir da distribuicao atual de pontos associados a cada agrupamento (cluster)
# Argumentos: nenhum
# Retorno: nenhum

calculateCentroids:
    la a3 centroids # Carrega o vector centroids
    la t4 k
    lw t4 0(t4) # Carrega o numero de centroids
    li a7 0 # centroid index
    loop_clusters:
        beqz t4 end_funct
        la t0 points # Carrega o vetor de pontos
        li a5 0 # Indexer for loop clusters
        lw t1 n_points # Carrega o numero de pontos a processar
        add t5 t1 x0 # Carrega o numero de pontos para registo auxiliar 
        li t2 0 # Soma dos Xs
        li t3 0 # Soma dos Ys
        li a2 0 # Numero de pontos no cluster
        la a4 clusters # Carrega o vector clusters
        loop_centroid:
            beqz t1 end_loop # Confirma se o numero de pontos a processar é 0, se for, vai para end_loop
            lw a0 0(t0) # carregar primeira coordenada
            lw a1 4(t0) # carregar a segunda coordenada
            lw a6 0(a4) # Carregar o cluster que o ponto pertence
            bne a7 a6 dont_sum # Verificar se o ponto é do cluster, se for soma, se não for nao soma
            sum: 
                add t2 t2 a0 # soma X ao t2
                add t3 t3 a1 # Soma Y ao t3
                addi a2 a2 1 # Adiciona 1 à contagem de pontos
            dont_sum:
                addi t0 t0 8 # avanca 2 posicoes no vector
                addi t1 t1 -1 # Reduz o numero de pontos a processar
                addi a5 a5 1 # adiciona 1 ao index do vector
                addi a4 a4 4 # Avanca para proxima posicao do vetor clusters
                j loop_centroid
        end_loop:
            
            div t6 t2 a2 # divide a soma pela numero de pontos
            div t2 t3 a2 # divide a soma pelo numero de pontos
            sw t6 0(a3) # escreve a media dos Xs no vector centroids
            sw t2 4(a3) # escreve a medias dos Ys no vetor centroids
            addi a3 a3 8 # Avanca 2 posicoes no vector centroids
            addi a7 a7 1 # Avanca o index do loop dos clusters 1
            addi t4 t4 -1 # reduz o numero de clusters a processar
            j loop_clusters
    end_funct:
        jr ra



### mainSingleCluster
# Funcao principal da 1a parte do projeto.
# Argumentos: nenhum
# Retorno: nenhum

mainSingleCluster:
    
    #1. Coloca k=1 (caso nao esteja a 1)
    #la t0 k # Carrega a address do k 
    #addi t1 x0 1 # Colocamos o k a 1
    #sw t1 0(t0) # Guardamos o k na sua address
    
    #2. cleanScreen
    addi sp sp -4 # Cria espaço na stack para guardar um registo
    sw ra 0(sp) # Guarda a ra na stack
    #jal cleanScreen # Chama a funcao cleanScreen
    lw ra 0(sp) # Recupera a ra 
    addi sp sp 4 # Repoe a posicao da stack 
    
    #3. printClusters
    addi sp sp -4 # Cria espaço na stack para guardar um registo
    sw ra 0(sp) # Guarda a ra na stack
    jal printClusters # Chama a funcao printClusters
    lw ra 0(sp) # Recupera a ra 
    addi sp sp 4 # Repoe a posicao da stack 

    #4. calculateCentroids
    addi sp sp -4 # Cria espaço na stack para guardar um registo
    sw ra 0(sp) # Guarda a ra na stack
    jal calculateCentroids # Chama a funcao calculateCentroid
    lw ra 0(sp) # Recupera a ra 
    addi sp sp 4 # Repoe a posicao da stack 

    #5. printCentroids
    addi sp sp -4 # Cria espaço na stack para guardar um registo
    sw ra 0(sp) # Guarda a ra na stack
    jal printCentroids # Chama a funcao printCentroid
    lw ra 0(sp) # Recupera a ra 
    addi sp sp 4 # Repoe a posicao da stack 
    #6. Termina
    jr ra



###generateCentroids:
# Inicializa os valores iniciais do vector centroids 
# Argumentos: 
# k : numero de clusters
# Retorno: nenhum

generateCentroids:
    la a2 centroids # Carrega o vetor centroids
    la t0 k #carrega a address do k
    lw a4 0(t0) # carrega o valor do k
    loop_centroids: blez a4 end_centroids # Testa se o k é zero, caso seja, vai para o end_centroids
    addi sp sp -4 # Cria espaço na stack para guardar um registo
    sw ra 0(sp) # Guarda a ra na stack
    jal randomPoint # Chama o randomPoint para gerar um ponto pseudo aleatorio
    sw a0 0(a2) # Grava a primeira coordenada do ponto
    sw a1 4(a2) # Grava a segunda coordenada do ponto
    addi a2 a2 8 # Avanca 2 posicoes no vector
    lw ra 0(sp) # Recupera a ra 
    addi sp sp 4 # Repoe a posicao da stack 
    addi a4 a4 -1 # reduz o numero de centroids a gerar
    j loop_centroids
    end_centroids:jr ra


### randomPoint
# Devolve um ponto de coordenadas pseudo aleatorias (x,y)
# Argumentos:
# nenhum
# Retorno:
# a0, a1: x, y

randomPoint:
    # Carrega a seed
    la t0, seed
    lw t1, 0(t0)

    # Calcula a nova Seed: seed = (seed * 1103515245 + seed) % (2^31)
    li t2, 1103515245
    mul t1, t1, t2
    add t1, t1, t0
    li t2, 0x7fffffff
    and t1, t1, t2

    # Gera um numero pseudo-aleatorio entre 0 e 31
    andi a0, t1, 31
    addi a0, a0, 1
    
    # Calcula a nova Seed: seed = (seed * 1103515245 + seed) % (2^31)
    li t2, 1103515245
    mul t1, t1, t2
    add t1, t1, t0
    li t2, 0x7fffffff
    and t1, t1, t2
    
    # Gera um numero pseudo-aleatorio entre 0 e 31
    andi a1, t1, 31
    addi a1, a1, 1
    
    # Store the new seed
    sw t1, 0(t0)
    jr ra

### manhattanDistance
# Calcula a distancia de Manhattan entre (x0,y0) e (x1,y1)
# Argumentos:
# a0, a1: x0, y0
# a2, a3: x1, y1
# Retorno:
# a0: distance

manhattanDistance:
    sub t0 a0 a2 # Subtracao do x0 e x1 - Distancia no eixo dos x
    sub t1 a1 a3 # Subtracao do y0 y1  - Distancia no eixo dos y
    bltz t0 abs_0 # Confirma se o primeiro resultado é um numero positivo, se não for passa para abs_0
    abs_check: bltz t1 abs_1 # Confirma se o segundo resultado é positivo, se não for passa para abs_1
    result: add a0 t0 t1 # Resultado final, adiciona a distancia dos x e distancia dos y e coloca no a0
    jr ra
    abs_0: # O numero é negativo, temos de converter em positivo invertendo os seus bits e adicionando 1
        not t0 t0 # inverte os bits
        addi t0 t0 1 # adiciona 1
        j abs_check
    abs_1: # O numero é negativo, temos de converter em positivo invertendo os seus bits e adicionando 1
        not t1 t1 # inverte os bits
        addi t1 t1 1 # Adiciona 1
        j result

### nearestCluster
# Determina o centroide mais perto de um dado ponto (x,y).
# Argumentos:
# a0, a1: (x, y) point
# Retorno:
# a0: cluster index

nearestCluster:
    la t6 centroids #Carrega o vector dos centroids para o registo t0
    la t5 k # Carrega a address do k
    lw t5 0(t5) # Carrega o valor do k no registo t5
    li a5 33 # Variavel para guardar o valor minimo
    li a6 0 # Variavel para guardar o index do cluster
    li t3 0 # Variavel para contabilizar a iteração
    check_distance:
        lw a2 0(t6) # Carrega a primeira coordenada do centroid para o a2
        lw a3 4(t6) # Carrega a segunda coordenada do centroid para o a3
        addi t6 t6 8 # Avanca 2 posicoes no vetor para o proximo ponto
        addi sp sp -12 # Adiciona espaco ao stack para guardar o ra, a0 e a1
        sw ra 0(sp) # Guarda o ra no stack
        sw a0 4(sp) # Guarda o a0
        sw a1 8(sp) # Guarda o a1
        jal manhattanDistance # Calcula a distancia do ponto ao centroid
        mv t0 a0 # A passar resultado do manhattanDistance
        lw ra 0(sp) # Carrega o ra 
        lw a0 4(sp) # Recupera o a0 original
        lw a1 8(sp) # Recupera o a1 original
        addi sp sp 12 # Repoe o sp
        blt a5 t0 dont_save
        save: # se novo valor é inferior ao que está em registo (a5) substitui o a5
            mv a5 t0 # Guarda a distancia calculada na manhattanDistance
            mv a6 t3 # Guarda index do centroid
        dont_save: # Novo valor não é inferior, nao grava
            addi t3 t3 1 # Avanca 1 posicao no vetor clusters
            addi t5 t5 -1 # Reduz o numero de centroids a processa a processar
            bnez t5 check_distance # verifica se o k é zero, se não for, volta a fazer o loop
    mv a0 a6 # Colocar o resultado na variavel a0
    jr ra

### populateCluster
# Verifica e guarda a que cluster pertence cada ponto no vector cluster
# Argumentos: nenhum
# Retorno: 
# a0: if points where changed or not

populateCluster:
    # OPTIMIZATION - Antes de guardar a informação de qual o cluster mais proximo, verifica
    # se a informação que lá está é diferente. Se for diferente coloca o a0 a 1, informando 
    # a função que chamou esta que houve alterações. Não duplica memoria.
    la a5 n_points # Carrega a address do numero de pontos
    lw a5 0(a5) # Carrega o numero de pontos no vetor
    la a3 points # Carrega a address do vetor dos ponto    la s3 points # Carrega a address do vetor dos pontoss
    la a4 clusters # carrega a Address do vetor clusters
    li a2 0 # Verificador se clusters alteraram
    loop_points: 
        beqz a5 end_populate # verifica se ainda há pontos a verificar, se nao ha, passa para end_populate
        lw a0 0(a3) # Carrega a primeira coordenada do ponto em a0
        lw a1 4(a3) # Carrega a segunda coordenada do ponto no a1
        addi sp sp -20 # Adiciona espaco ao stack para guardar o ra
        sw a2 16(sp) # Guada o a2 no stack
        sw a4 12(sp) # Guarda o a4 no stack
        sw a3 8(sp) # Guarda o a3 no stack
        sw a5 4(sp) # Guarda o a5 no stack
        sw ra 0(sp) # Guarda o ra no stack
        jal nearestCluster
        lw ra 0(sp) # Carrega o ra
        lw a5 4(sp) # Recupera o a5 do stack
        lw a3 8(sp) # Recupera o a3 do stack
        lw a4 12(sp) # Recupera o a4 do stack
        lw a2 16(sp) # recupera o a2 do stack
        addi sp sp 20 # Repoe o sp
        lw a6 0(a4) # Carrega o valor que estava antes
        bne a6 a0 changed_record # Verifica se valor que está no vector é igaul ao calculado, caso não seja, coloca a variavel a2 a 1
        resume: sw a0 0(a4) # Grava o resultado da funcao nearestCluster no vetor clusters
        addi a4 a4 4 # Avança o vector clusters para a proxima posicao
        addi a3 a3 8 # avanca 2 posicoes no vector points
        addi a5 a5 -1 # Reduz o numero de pontos a processar
        j loop_points
    end_populate: 
        mv a0 a2 # Carregando o resultado para a varivel de retorno
        jr ra
    changed_record:
        li a2 1 # Grava informacao que os registos foram alterados
        j resume



### mainKMeans
# Executa o algoritmo *k-means*.
# Argumentos: nenhum
# Retorno: nenhum

mainKMeans:  
    la a1 L
    lw a1 0(a1) # Carregar o numero de iteracoes maximas do algoritmo
    addi a1 a1 -1 # Contabilizar a primeira iteração
    addi sp sp -4 # Adiciona espaço ao stack para guardar variavel
    sw a1 0(sp) # A guardar o valor na stack
    
    # 1. Gera centroids pseudo-aleatorios
    addi sp sp -4 # Adiciona espaco ao stack para guardar o ra
    sw ra 0(sp) # Guarda o ra no stack
    jal generateCentroids # Gera centroids pseudo aleatorios
    lw ra 0(sp) # Carrega o ra 
    addi sp sp 4 # Repoe o sp
    
    
    # 3. Verifica a que cluster cada ponto pertence e grava no vetor clusters
    addi sp sp -4 # Adiciona espaco ao stack para guardar o ra
    sw ra 0(sp) # Guarda o ra no stack
    jal populateCluster
    lw ra 0(sp) # Carrega o ra 
    addi sp sp 4 # Repoe o sp
        
    # 4. Print os Centroids
    addi sp sp -4 # Adiciona espaco ao stack para guardar o ra
    sw ra 0(sp) # Guarda o ra no stack
    jal printCentroids # Imprime os centroids
    lw ra 0(sp) # Carrega o ra 
    addi sp sp 4 # Repoe o sp
    
    # 5. Print dos pontos com cor correspondente
    addi sp sp -4 # Adiciona espaco ao stack para guardar o ra
    sw ra 0(sp) # Guarda o ra no stack
    jal printClusters # Imprime os pontos nas respetivas cores
    lw ra 0(sp) # Carrega o ra 
    addi sp sp 4 # Repoe o sp    
    
    loop_iteracao:
        lw a1 0(sp)
        beqz a1 end_algo # Confirma se já iteramos as L vezes
        addi a1 a1 -1 # Retira uma iteracao a processar
        sw a1 0(sp) # Volta a guardar na stack
        
        # 2. Limpa ecra
        addi sp sp -4 # Adiciona espaco ao stack para guardar o ra
        sw ra 0(sp) # Guarda o ra no stack
        jal cleanScreen # Limpa o ecra
        lw ra 0(sp) # Carrega o ra 
        addi sp sp 4 # Repoe o sp
    
        # 4. Recalcula as médias dos clusters
        addi sp sp -4 # Adiciona espaco ao stack para guardar o ra
        sw ra 0(sp) # Guarda o ra no stack
        jal calculateCentroids
        lw ra 0(sp) # Carrega o ra 
        addi sp sp 4 # Repoe o sp
        
        # 5. refaz os clusters de acordo com os novos centroids
        addi sp sp -4 # Adiciona espaco ao stack para guardar o ra
        sw ra 0(sp) # Guarda o ra no stack
        jal populateCluster
        mv a4 a0 # Carregando o resultado de populate Cluster
        lw ra 0(sp) # Carrega o ra 
        addi sp sp 4 # Repoe o sp
        

        # 7. Print dos pontos com cor correspondente
        addi sp sp -4 # Adiciona espaco ao stack para guardar o ra
        sw ra 0(sp) # Guarda o ra no stack
        jal printClusters # Imprime os pontos nas respetivas cores
        lw ra 0(sp) # Carrega o ra 
        addi sp sp 4 # Repoe o sp    
        
        # 6. Print os Centroids
    
        addi sp sp -4 # Adiciona espaco ao stack para guardar o ra
        sw ra 0(sp) # Guarda o ra no stack
        jal printCentroids # Imprime os centroids
        lw ra 0(sp) # Carrega o ra 
        addi sp sp 4 # Repoe o sp
        
        beqz a4 end_algo # Verifica se houve alteracao na ultima iteracao
        j loop_iteracao
    
    end_algo:jr ra
    
    
