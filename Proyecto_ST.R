
#                            Proyecto SERIES DE TIEMPO

# (6)  Avila Argüello Carlos
# (10) Bonilla Cruz José Armando
# (39) Luna Gutierrez Yanely
# (64) Reyes González Belén
# (67) Rivera Mata Dante Tristán

#   librerías                                                     ----                                              
library(fpp2)
library(ggplot2)
library(TSA)
library(timeDate)
library(timeSeries)
library(fpp)
library(forecast)
library(fTrading)
library(readr)
library(dplyr)
library(xts)
library(car)
library(nortest)
library(astsa)
library(ggfortify)
library(ggpmisc)
library(cowplot)
library(gridExtra)
library(tidyr)

#     Cargar la base                                              ----
avocado <- read_csv("C:\\Users\\carlo\\OneDrive\\Documentos\\Facultad de Ciencias\\Estadística\\Series de tiempo\\Proyectos\\avocado.csv", col_types = cols(Date = col_character(), region = col_character()))
summary(avocado)
windowsFonts(CG = windowsFont('TT Century Gothic'))
avocado$Date<-as.Date(avocado$Date)
conventional_avocado <- filter(avocado[,c(2,3,4,12,14)],type=='conventional',region == 'TotalUS')
conventional_avocado$`Total Volume`<-conventional_avocado$`Total Volume`*0.000453592
volumen_series <- conventional_avocado[,c(1,3)]

volumen_series <- xts(volumen_series,order.by = volumen_series$Date) 
volumen_series <- ts(as.numeric(volumen_series$`Total Volume`),start = c(2015,01,04),frequency = 52)

# No hay datos faltantes
fecha_in<-as.Date("2015-01-04")
fecha_fin<-as.Date("2018-03-25")
difftime(fecha_fin,fecha_in, units = "weeks")+1
dim(conventional_avocado)[1]

#                                        Análisis Descriptivo     -----

autoplot(volumen_series, ts.colour = '#6baed6', ts.size = 0.8)+
  scale_y_continuous(labels = scales::comma)+
  labs(y = 'Volumen (toneladas)', x = 'AÃ±o')+
  ggtitle('Volumen de aguacate vendido') +  theme_minimal() +
  theme(plot.title = element_text(size= 12, hjust = 0.5, family = 'CG'),
        axis.title.x = element_text(size = 10, color = 'grey20', family = 'CG'),
        axis.title.y = element_text(size = 10, color = 'grey20', family = 'CG')) 

#Asimetria                  #Kurtósis
skewness(volumen_series);  kurtosis(volumen_series)
sk <- round(as.numeric(skewness(volumen_series)), 2)
ku <- round(as.numeric(kurtosis(volumen_series)), 2)
table <- data.frame(Asimetría=sk, Curtosis = ku)

#Histograma
ggplot(volumen_series, aes(x = volumen_series, fill = ..x..))+
  geom_histogram(aes(y = ..density..),color = 'white', alpha = 0.8)+
  scale_fill_gradient(low='#deebf7', high='#2171b5')+
  geom_density(color = '#deebf7', size = 0.7, fill = '#9ecae1', alpha = 0.2)+
  geom_vline(aes(xintercept = mean(volumen_series)), linetype = 'dashed', color = '#2171b5', size = 0.8)+
  scale_y_continuous(labels = scales::percent)+
  scale_x_continuous(labels = scales::comma)+
  labs(y = 'Densidad', x = 'Toneladas de aguacate')+
  ggtitle('Volumen de aguacate') +  theme_minimal() +
  theme(plot.title = element_text(size= 12, hjust = 0.5, family = 'CG'),
        axis.title.x = element_text(size = 10, color = 'grey20', family = 'CG'),
        axis.title.y = element_text(size = 10, color = 'grey20', family = 'CG'),
        legend.position="none")

#BoxPlot
ggplot(volumen_series, aes(y = volumen_series))+ 
  geom_boxplot(color = '#525252', fill = '#1d91c0', alpha = 0.4, size = 0.6)+
  scale_y_continuous(labels = scales::comma)+
  labs(y = 'Toneladas de aguacate')+
  ggtitle('Volumen de aguacate') +  theme_minimal() +
  theme(plot.title = element_text(size= 12, hjust = 0.5, family = 'CG'),
        axis.title.x = element_text(size = 10, color = 'grey20', family = 'CG'),
        axis.title.y = element_text(size = 10, color = 'grey20', family = 'CG'))

#BoxPlot cíclico
df <- data.frame(cycle(volumen_series),volumen_series)
col <- colorRampPalette(c("#edf8b1", "#1d91c0"))

ggplot(df)+
  geom_boxplot(aes(x = as.factor(cycle.volumen_series.), y = volumen_series, 
                   fill = as.factor(cycle.volumen_series.)), color = '#525252')+
  scale_fill_manual(values = col(52))+
  scale_y_continuous(labels = scales::comma)+
  scale_x_discrete(breaks=seq(0, 52,5))+
  labs(y = 'Toneladas', x = 'Semana')+
  ggtitle('Volumen de aguacate') +  theme_minimal() +
  theme(plot.title = element_text(size= 12, hjust = 0.5, family = 'CG'),
        axis.title.x = element_text(size = 10, color = 'grey20', family = 'CG'),
        axis.title.y = element_text(size = 10, color = 'grey20', family = 'CG'),
        legend.position="none")

#     Calculamos las componentes                                  --------

xt <- log(volumen_series)
d = frequency(volumen_series)
k = 3 #Numero de años
n = length(volumen_series)
q = d/2

mt = ts(rep(NA,n),start =start(xt), frequency = d)
for (t in (q+1):(n-q)) {
  mt[t]= (.5*xt[t-q]+sum(xt[(t-q+1):(t+q-1)])+.5*xt[t+q])/(d)
}
mt[1:q] = mt[q+1]
mt[(n-q+1):n] = mt[n-q]

zt = xt - mt
wk = c()
for (i in 1:d) {
  wk[i]=sum(zt[(0:(k-1))*52+i])/k
}
sk=c()
for(i in 1:52){
  sk[i] = wk[i] - (sum(wk)/d)
}        
st = ts(rep(sk,times = k),start = start(xt), frequency = d)

yt = zt - st
comp = mt + st
comonente = ts(comp,start = start(xt), frequency = d)

# Graficar las componentes
decompose_vs <- decompose(volumen_series, 'multiplicative')

p1 <- autoplot(decompose_vs$x, ts.colour = '#a8ddb5', ts.size = 0.8)+
  scale_y_continuous(labels = scales::comma)+
  ggtitle('Datos observados') + theme_minimal()+
  theme(plot.title = element_text(size= 11, hjust = 0.5, family = 'CG'),
        axis.title.x=element_blank(), axis.text.x=element_blank(),
        axis.ticks.x=element_blank()) 

p2 <- autoplot(mt, ts.colour = '#7bccc4', ts.size = 0.8)+
  scale_y_continuous(labels = scales::comma)+
  ggtitle('Tendencia') + theme_minimal()+
  theme(plot.title = element_text(size= 11, hjust = 0.5, family = 'CG'),
        axis.title.x=element_blank(), axis.text.x=element_blank(),
        axis.ticks.x=element_blank()) 

p3 <- autoplot(st, ts.colour = '#4eb3d3', ts.size = 0.8)+
  scale_y_continuous(labels = scales::comma)+
  ggtitle('Ciclos') + theme_minimal()+
  theme(plot.title = element_text(size= 11, hjust = 0.5, family = 'CG'),
        axis.title.x=element_blank(), axis.text.x=element_blank(),
        axis.ticks.x=element_blank()) 

p4 <- autoplot(yt, ts.colour = '#2b8cbe', ts.size = 0.8)+
  scale_y_continuous(labels = scales::comma)+
  labs(x = 'AÃ±o')+
  ggtitle('Aleatorio') + theme_minimal()+
  theme(plot.title = element_text(size= 11, hjust = 0.5, family = 'CG'),
        axis.title.x = element_text(size = 10, color = 'grey20', family = 'CG')) 

grid.arrange(p1, p2, p3, p4, ncol=1)

#                                        Análisis Estadístico     -----

#Creamos una función para la validación de los supuestos

validacion_supuestos <- function(modelo){
  #AIC
  AIC <- modelo$aic
  #BIC
  BIC <- modelo$bic
  #MAE
  MAE <- sum(abs(modelo$fitted - modelo$x))/length(modelo$x)
  #Homocedasticidad
  par(mfrow=c(1,3))
  plot(modelo$residuals)
  acf(modelo$residuals)
  pacf(modelo$residuals)
  #Media cero
  Media_cero <- t.test(modelo$residuals)$p.value
  #No correlaciÃ³n
  tsdiag(modelo,lag=52)
  #Normalidad
  Normalidad <- ad.test(modelo$residuals)$p.value
  df <- data.frame(AIC,BIC,MAE,Media_cero,Normalidad)
  return(df)
}

# En busca de un buen modelo
#     Datos sin transformar                                       ----
#Calculemos el número de diferencias sugeridas
nsdiffs(volumen_series)
ndiffs(volumen_series)

#Verifiquemos las diferencias necesarias
acf(volumen_series, lag.max = 100)
volumen_series_dif <- diff(volumen_series, lag = 52)
volumen_series_dif_dif <- diff(volumen_series_dif)
acf(volumen_series_dif_dif, lag.max = 100)
acf(volumen_series_dif, lag.max = 100)

#Verificar estacionariedad para "estimar" los parámetros:
adf.test(volumen_series_dif_dif)
kpss.test(volumen_series_dif_dif)
pp.test(volumen_series_dif_dif)

adf.test(volumen_series)
kpss.test(volumen_series)
pp.test(volumen_series)

#Propuestas

  # ARMA(1,1)
    arma1_1 <- arima(volumen_series_dif_dif, order = c(1, 0, 1)) 
    summary(arma1_1)
    confint(arma1_1)
    BIC(arma1_1)

    #Validacion Supuestos
      #Normalidad
      ad.test(arma1_1$residuals)
      shapiro.test(arma1_1$residuals)
      qqnorm(arma1_1$residuals)
      qqline(arma1_1$residuals)
      #Homocedasticidad
      plot(arma1_1$residuals)
      #Media Cero
      t.test(arma1_1$residuals)
      #No correlaciÃ³n
      tsdiag(arma1_1)

  # Auto Arima SARIMA(0,1,0)(1,1,0)[52]
    volumen_series_auto <- auto.arima(volumen_series)
    volumen_series_auto
    confint(volumen_series_auto)
    
    #Validacion Supuestos
      validacion_supuestos(volumen_series_auto)
      par(mfrow = c(1,1))
      #Homocedasticidad
      plot(volumen_series_auto$residuals)
      #Media Cero
      t.test(volumen_series_auto$residuals)
      #No correlaciÃ³n
      tsdiag(volumen_series_auto)
#     Transformación BoxCox                                       ----
lambda <- BoxCox.lambda(volumen_series)
lambda # lambda ees prÃ¡cticamente igual a -1
vol_boxcox <- volumen_series^lambda
plot(vol_boxcox, main = "vol_boxcox de Aguacate vendido", col = "orange", lwd = 2,
     ylab=" Box cox Volumen (en toneladas)",xlab="AÃ±o")

#Busquemos el parámetro de diferencias
nsdiffs(vol_boxcox) #Parte estacional
ndiffs(vol_boxcox) 

vol_boxcox_dif <- diff(vol_boxcox, lag=52)
plot(vol_boxcox_dif)
plot(decompose(vol_boxcox_dif))
acf(vol_boxcox_dif, lag.max = 52)
pacf(vol_boxcox_dif, lag.max = 52)

vol_boxcox_dif_dif <- diff(vol_boxcox_dif)
plot(vol_boxcox_dif_dif)
plot(decompose(vol_boxcox_dif_dif))

acf(vol_boxcox_dif_dif, lag.max = 52)
pacf(vol_boxcox_dif_dif, lag.max = 52)

#Verificar estacionariedad para "estimar" los parámetros:
adf.test(vol_boxcox_dif_dif)
kpss.test(vol_boxcox_dif_dif)
pp.test(vol_boxcox_dif_dif)

# Propuestas

# Box Cox 1
  
  #SARIMA(0,0,1)(0,1,0)[52]
    modelo_boxcox_1 <- arima(vol_boxcox,order=c(0,0,1), seasonal = list(order=c(0,1,0),period = 52))
    summary(modelo_boxcox_1)
    confint(modelo_boxcox_1)
    BIC(modelo_boxcox_1)
  
    #Validacion Supuestos
      #Homocedasticidad
      plot(modelo_boxcox_1$residuals)
      #Media Cero
      t.test(modelo_boxcox_1$residuals)
      #No correlaciÃ³n
      tsdiag(modelo_boxcox_1)
      #Normalidad
      ad.test(modelo_boxcox_1$residuals)
      shapiro.test(modelo_boxcox_1$residuals)
      qqnorm(modelo_boxcox_1$residuals)
      qqline(modelo_boxcox_1$residuals)

# Box Cox 2
  
  #SARIMA(0,1,1)(0,1,0)[52]
    modelo_boxcox_2 <- arima(vol_boxcox,order=c(0,1,1), seasonal = list(order=c(0,1,0),period = 52))
    summary(modelo_boxcox_2)
    confint(modelo_boxcox_2)
    BIC(modelo_boxcox_2)
  
    #Validacion Supuestos
      #Homocedasticidad
      plot(modelo_boxcox_2$residuals)
      #Media Cero
      t.test(modelo_boxcox_2$residuals)
      #No correlaciÃ³n
      tsdiag(modelo_boxcox_2)
      #Normalidad
      ad.test(modelo_boxcox_2$residuals)
      shapiro.test(modelo_boxcox_2$residuals)
      qqnorm(modelo_boxcox_2$residuals)
      qqline(modelo_boxcox_2$residuals) 

# Autoarima BoxCox
    
    modelo_boxcox_3 <- auto.arima(vol_boxcox)
    summary(modelo_boxcox_3)
    confint(modelo_boxcox_3)

    #Validacion Supuestos
        validacion_supuestos(modelo_boxcox_3)
        par(mfrow = c(1,1))
        #Homocedasticidad
        plot(modelo_boxcox_3$residuals)
        #Media Cero
        t.test(modelo_boxcox_3$residuals)
        #No correlaciÃ³n
        tsdiag(modelo_boxcox_3)
        #Normalidad
        ad.test(modelo_boxcox_3$residuals)
        shapiro.test(modelo_boxcox_3$residuals)
        qqnorm(modelo_boxcox_3$residuals)
        qqline(modelo_boxcox_3$residuals)


#     Transformación Logarítmo Natural                            ----
log_volumen_series <- log(volumen_series)
plot(log_volumen_series, main = "LOG_Volumen de Aguacate vendido", col = "orange", lwd = 2,
     ylab=" log Volumen (en toneladas)",xlab="AÃ±o")
boxplot(log_volumen_series~cycle(log_volumen_series))

#Veamos el cálculo de los parámetros
  nsdiffs(log_volumen_series)
  ndiffs(log_volumen_series)
  
  log_volumen_series_dif <- diff(log_volumen_series, lag=52)
  log_volumen_series_dif_dif <- diff(log_volumen_series_dif)
  
  plot(log_volumen_series_dif_dif)
  plot(decompose(log_volumen_series_dif_dif))
  
  acf(log_volumen_series_dif_dif, lag.max = 52)
  pacf(log_volumen_series_dif_dif, lag.max = 52)

#Verificar estacionariedad para "estimar" los parámetros:
  adf.test(log_volumen_series_dif_dif)
  kpss.test(log_volumen_series_dif_dif)
  pp.test(log_volumen_series_dif_dif)
  validacion_supuestos(auto.arima(log_volumen_series_dif_dif))

# Propuestas

  # Autoarima log
    volumen_series_log_auto <- auto.arima(log_volumen_series)
    summary(volumen_series_log_auto)
    
    confint(volumen_series_log_auto)
  
    #Validacion Supuestos
      validacion_supuestos(volumen_series_log_auto)
      par(mfrow = c(1,1))
      #Homocedasticidad
      plot(volumen_series_log_auto$residuals)
      #Media Cero
      t.test(volumen_series_log_auto$residuals)
      #No correlaciÃ³n
      tsdiag(volumen_series_log_auto)
      #Normalidad
      ad.test(volumen_series_log_auto$residuals)
      shapiro.test(volumen_series_log_auto$residuals)
      qqnorm(volumen_series_log_auto$residuals)
      qqline(volumen_series_log_auto$residuals)

  # Logaritmo 1
    # SARIMA(0,1,1)(0,1,0)[52]
      modelo_propuesta <- arima(log_volumen_series,order=c(0,1,1), seasonal = list(order=c(0,1,0),period = 52))
      summary(modelo_propuesta)
      confint(modelo_propuesta)
      BIC(modelo_propuesta)
  
      #Validacion Supuestos
        #Homocedasticidad
        plot(modelo_propuesta$residuals)
        #Media Cero
        t.test(modelo_propuesta$residuals)
        #No correlaciÃ³n
        tsdiag(modelo_propuesta)
        #Normalidad
        ad.test(modelo_propuesta$residuals)
        shapiro.test(modelo_propuesta$residuals)
        qqnorm(modelo_propuesta$residuals)
        qqline(modelo_propuesta$residuals)
        hist(modelo_propuesta$residuals)
        ggplot(modelo_propuesta$residuals, aes(x = modelo_propuesta$residuals, fill = ..x..))+
          geom_histogram(aes(y = ..density..),color = 'white', alpha = 0.8)+
          scale_fill_gradient(low='#deebf7', high='#2171b5')+
          geom_density(color = '#deebf7', size = 0.7, fill = '#9ecae1', alpha = 0.2)+
          stat_function(fun = dnorm, args = list(mean=mean(modelo_propuesta$residuals), sd = sqrt(var(modelo_propuesta$residuals))), 
                        col = "#045a8d", size = .8) +
          geom_vline(aes(xintercept = mean(modelo_propuesta$residuals)), linetype = 'dashed', color = '#2171b5', size = 0.8)+
          scale_y_continuous(labels = scales::percent)+
          scale_x_continuous(labels = scales::comma)+
          labs(y = 'Densidad', x = 'Residuos')+
          ggtitle('Volumen vs Modelo') +  theme_minimal() +
          theme(plot.title = element_text(size= 12, hjust = 0.5, family = 'CG'),
                axis.title.x = element_text(size = 10, color = 'grey20', family = 'CG'),
                axis.title.y = element_text(size = 10, color = 'grey20', family = 'CG'),
                legend.position="none")

      #Predicción
      plot(forecast(log_volumen_series, model = modelo_propuesta, h = 52))
      
      p <- forecast(log_volumen_series, model = modelo_propuesta, h = 52)  
      
      x <- seq.Date(fecha_in,fecha_fin, by = 'week')
      y <- as.numeric(log_volumen_series)
      x_1 <- seq.Date(as.Date("2018-04-01"), as.Date("2019-03-24"), by = "week")
      y_1 <- as.numeric(p$mean)
      lower_80 <- as.numeric(p[[5]][,1])
      upper_80 <- as.numeric(p[[6]][,1])
      lower_95 <- as.numeric(p[[5]][,2])
      upper_95 <- as.numeric(p[[6]][,2])
      
      
      ggplot()+
        geom_line(aes(x = x, y = y, color = "Logaritmo"), size = 0.8)+
        geom_ribbon(aes(x = x_1, ymax = upper_80, ymin = lower_80, fill = '80%'), alpha = 0.5)+
        geom_ribbon(aes(x = x_1, ymax = upper_95, ymin = lower_95, fill = '95%'), alpha = 0.2)+
        geom_line(aes(x = x_1, y = y_1, color = "Predicción"), size = 0.8)+
        scale_fill_manual(values =c('#c6dbef','#9ecae1'), name = 'Bandas')+
        scale_color_manual(values = c('#51B1D4', '#3896B8'), name = 'Serie')+
        labs(y = 'Log(toneladas de aguacate)', x = 'Año')+
        ggtitle('Predicción SARIMA(0,1,1)(0,1,0)[52] (logarítmo)') +  theme_minimal() +
        theme(plot.title = element_text(size= 12, hjust = 0.5, family = 'CG'),
              axis.title.x = element_text(size = 10, color = 'grey20', family = 'CG'),
              axis.title.y = element_text(size = 10, color = 'grey20', family = 'CG'))


# Logaritmo 2  
  # SARIMA(1,1,1)(0,1,0)[52]
    modelo_propuesta_1 <- arima(log_volumen_series,order=c(1,1,1), seasonal = list(order=c(0,1,0),period = 52))
    summary(modelo_propuesta_1)
    confint(modelo_propuesta_1)
    BIC(modelo_propuesta_1)

    #Validación Supuestos
      #Homocedasticidad
      plot(modelo_propuesta_1$residuals)
      #Media Cero
      t.test(modelo_propuesta_1$residuals)
      #No correlaciÃ³n
      tsdiag(modelo_propuesta_1)
      #Normalidad
      ad.test(modelo_propuesta_1$residuals)
      shapiro.test(modelo_propuesta_1$residuals)
      qqnorm(modelo_propuesta_1$residuals)
      qqline(modelo_propuesta_1$residuals)

#     HoltWinters                                                 ----
      hw_vs <- HoltWinters(volumen_series, seasonal = "additive")
      predict_1 <- predict(hw_vs, 52, prediction.interval = TRUE)
      
      y_2 <- as.numeric(volumen_series)
      y_3 <- as.numeric(predict_1[,1])
      upper <- as.numeric(predict_1[,2])
      lower <- as.numeric(predict_1[,3])
      
      ggplot()+
        geom_line(aes(x = x, y = y_2, color = "Datos"), size = 0.8)+
        geom_ribbon(aes(x = x_1, ymax = upper, ymin = lower, fill = '95%'), alpha = 0.35)+
        geom_line(aes(x = x_1, y = y_3, color = "Predicción"), size = 0.8)+
        scale_fill_manual(values =c('#FFC48E','#fdbb84'), name = 'Bandas')+
        scale_color_manual(values = c('#fd8d3c', '#f16913'), name = 'Serie')+
        labs(y = 'Toneladas de aguacate', x = 'Año')+
        ggtitle('Predicción Holt Winters') +  theme_minimal() +
        theme(plot.title = element_text(size= 12, hjust = 0.5, family = 'CG'),
              axis.title.x = element_text(size = 10, color = 'grey20', family = 'CG'),
              axis.title.y = element_text(size = 10, color = 'grey20', family = 'CG'))

#                                        Predicción               ----
# Haremos una validación cruzada para HW y 
# el "Modelo Propuesta" SARIMA(0,1,1)(0,1,0)[52] 

# El objetivo de buscar aquella predicción que tenga 
# un menor error medio estándar con respecto a las predicciones 
# y los valores "originales" de la serie.
      
      #Predecir los datos desde el 2018 para
      # el modelo propuesta
      volumen_training <- window(volumen_series,2015,2018)
      volumen_test <- window(volumen_series,start=2018)
      
      log_volumen_tr <- log(volumen_training)
      modelo_propuesta_tr <- arima(log_volumen_tr,order = c(0,1,1), 
                                   seasonal = list(order = c(0,1,0), period = 52))
      pred <-predict(modelo_propuesta_tr, n.ahead = 13)
      t1<-pred$pred-1.96*pred$se
      t2<-pred$pred+1.96*pred$se
      
      #Predecir los datos desde el 2018 para HW
      hw_vs_tr <- HoltWinters(volumen_training, seasonal = "multiplicative")
      
      predict_hw <- predict(hw_vs_tr, 13, prediction.interval = FALSE)
      predict_log <- exp(pred$pred)
      
      # Elementos de la gráfica
      fecha_aux <- as.Date("2018-01-07")
      x_c <- seq.Date(fecha_aux, fecha_fin, by = 'week')
      y_c1 <- as.numeric(volumen_test)[2:13]
      y_c2 <- as.numeric(predict_log)[1:12]
      y_c3 <- as.numeric(predict_1_tr)[1:12]
      
      #Vemos la grafica de la serie y las predicciones para el 2018
      hw_vs_tr <- HoltWinters(volumen_training, seasonal = "multiplicative")
      
      predict_hw <- predict(hw_vs_tr, 13, prediction.interval = T)
      predict_log <- exp(pred$pred)
      
      # Elementos de la gráfica
      fecha_aux <- as.Date("2018-01-07")
      x_c <- seq.Date(fecha_aux, fecha_fin, by = 'week')
      y_c1 <- as.numeric(volumen_test)[2:13]
      y_c2 <- as.numeric(predict_log)[1:12]
      y_c3 <- as.numeric(predict_hw[,1])[1:12]
      
      up_sa <- exp(as.numeric(t2))[1:12]
      low_sa <- exp(as.numeric(t1))[1:12]
      
      up_hw <- as.numeric(predict_hw[,2])[1:12]
      low_hw <- as.numeric(predict_hw[,3])[1:12]
      
      #Vemos la grafica de la serie y las predicciones para el 2018
      ggplot()+
        geom_ribbon(aes(x = x_c, ymax = up_sa, ymin = low_sa, fill = 'SARIMA'), alpha = 0.18)+
        geom_ribbon(aes(x = x_c, ymax = up_hw, ymin = low_hw, fill = 'Holt Winters'), alpha = 0.25)+
        geom_line(aes(x = x_c, y = y_c1, color = "Datos"), size = 1)+
        geom_line(aes(x = x_c, y = y_c2, color = "SARIMA"), size = 1)+
        geom_line(aes(x = x_c, y = y_c3, color = "Holt Winters"), size = 1)+
        scale_fill_manual(values = c('#609BB5', '#CBAA62'), name = 'Bandas')+
        scale_color_manual(values = c('#A3A3A3', '#609BB5', '#CBAA62'), name = 'Predicciones')+
        scale_y_continuous(labels = scales::comma)+
        labs(y = 'Toneladas de aguacate', x = '2018')+
        ggtitle('Comparación de modelos') +  theme_minimal() +
        theme(plot.title = element_text(size= 12, hjust = 0.5, family = 'CG'),
              axis.title.x = element_text(size = 10, color = 'grey20', family = 'CG'),
              axis.title.y = element_text(size = 10, color = 'grey20', family = 'CG'))
      
      n <- length(volumen_test)
      error_hw <- sum(abs(volumen_test-predict_1_tr))/n
      error_SARIMA <- sum(abs(volumen_test-pred$pred))/n
      
      error_hw < error_SARIMA
      #Esto implica que el error medio 
      #que se genera de la predicción HW
      #es menor que el de nuestra propuesta

      