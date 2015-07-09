require 'spec_helper'

describe NEAT::Neuron do
  before(:each) do
    @neuron = NEAT::Neuron.new(controllerfrei: true) 
  end

  context 'ast' do
    it 'has express_ast' do
      expect(@neuron.respond_to?(:express_ast)).to be true
    end
  end
end

describe NEAT::BasicNeuronTypes do
  before(:each) do
    @neurons = [InputNeuron,  BiasNeuron, SigmoidNeuron, 
                TanhNeuron,   SineNeuron, CosineNeuron,
                LinearNeuron, MulNeuron,  HeavisideNeuron,
                SignNeuron,   GaussianNeuron]
  end

  context 'AST' do
    it 'implements express_ast' do
      @neurons.each{ |klass|
        neu = klass.new(controllerfrei: true) 
        expect(neu.respond_to?(:express_ast)).to be true
        expect(neu.express_ast.kind_of?(Parser::AST::Node)).to be true
      }
    end
  end
end
