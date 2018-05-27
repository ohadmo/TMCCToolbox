import sys
import numpy as np
import math
import matplotlib.pyplot as plt

class Neuron:
    length = None
    width = None
    iterations_constant = None

    def __init__(self, x, y):
        self.countLabels = None
        self.countPatient = None

        self.X = x
        self.Y = y
        #self.nf = 1000/math.log(Neuron.length)
        self.weights = None
        self.samples_counter = 0

        self.resClass = []
        self.resLabel = []
        self.resPatient = []

        self.resTestClass = []
        self.resTestLabel = []
        self.resTestPatient = []

    def resetCountLabels(self,unique_labels):
        self.countLabels = {key:0 for key in unique_labels}

    def resetCountPatient(self, unique_array):
        self.countPatient = {key:0 for key in unique_array}

    def Gaussian(self, n, it):
        streng= math.exp(-it/self.nf)*Neuron.length
        distance = math.sqrt(math.pow(n.X - self.X, 2) + math.pow(n.Y - self.Y, 2))
        returned_value = math.exp(-math.pow(distance, 2)/(math.pow(streng, 2)))
        return returned_value
    
    def learningRate(self, iteration):
        return 0.1*math.exp(-iteration/1000)        
    
    def UpdateNeuronWeight(self, pattern, winner, iteration):
        wsum = 0
        for i in range(len(self.weights)):
            delta = self.learningRate(iteration) * self.Gaussian(winner,iteration) * (pattern[i]-self.weights[i])
            self.weights[i] = self.weights[i] + delta
            wsum = wsum + delta
        return wsum / len(self.weights)
           
    def calculateSigma(self,iIterationCount):
        #m_dMapRadius = (max(Neuron.length, Neuron.width)/2) *10   #2x2 grid causes division by zero
        m_dMapRadius = max(Neuron.length, Neuron.width)/2
        m_dTimeConstant = (Neuron.iterations_constant)/math.log(m_dMapRadius)
        m_dNeighbourhoodRadius = m_dMapRadius * math.exp(-iIterationCount/m_dTimeConstant)
        return m_dNeighbourhoodRadius
        
    def calculateL(self, iNumIterations, iIterationCount):
        constStartLearningRate = 0.1
        m_dLearningRate = constStartLearningRate * math.exp(-iIterationCount/Neuron.iterations_constant)
        return m_dLearningRate
        
    def calculateTheta(self, iteration, winner_n):
        dist = math.sqrt(math.pow(winner_n.X - self.X, 2) + math.pow(winner_n.Y - self.Y, 2))
        dist = -1*math.pow(dist,2)
        sig = 2*math.pow(self.calculateSigma(iteration), 2)
        return math.exp(dist/sig)

    def UpdateNeuronWeight_new(self, pattern, winner, m_iNumIterations, m_iIterationCount, obj):
        deltas_list = None
        m_dNeighbourhoodRadius = self.calculateSigma(m_iIterationCount)
        DistToNodeSq = math.pow(winner.X - self.X, 2) + math.pow(winner.Y - self.Y, 2)
        WidthSq = math.pow(m_dNeighbourhoodRadius, 2)
        if DistToNodeSq <= WidthSq:
            obj.rememberUpdates += 1
            m_dInfluence = math.exp(-(DistToNodeSq)/(2*WidthSq))
            deltas_list = self.calculateL(m_iNumIterations, m_iIterationCount) * m_dInfluence * np.subtract(pattern, self.weights)
            self.weights = np.add(self.weights, deltas_list)
        else:
            return 0
        if not obj.flag1:
            obj.CurrentRadius = math.sqrt(WidthSq)
            print("radius_width:", obj.CurrentRadius)
            obj.flag1 = True
        return np.sum(deltas_list)/len(self.weights)

    def UpdateNeuronWeight_newSecond(self, pattern, winner, m_iNumIterations, m_iIterationCount, obj):
        obj.rememberUpdates += 1
        deltas_list = self.calculateL(m_iNumIterations, m_iIterationCount) * self.calculateTheta(m_iIterationCount,winner) * np.subtract(pattern, self.weights)
        self.weights = np.add(self.weights, deltas_list)
        return np.sum(deltas_list) / len(self.weights)