module TestComponents

using Mimi
using Base.Test

import Mimi:
    reset_compdefs, compdefs, compdef, compkeys, hascomp, _compdefs, first_period, 
    last_period, compmodule, compname, numcomponents, dump_components, 
    dimensions

reset_compdefs()

@test length(_compdefs) == 3 #adder, ConnectorCompVector, ConnectorCompMatrix

my_model = Model()

#Try running model with no components
@test length(compdefs(my_model)) == 0
@test numcomponents(my_model) == 0
@test_throws ErrorException run(my_model)

#Now add several components to the module
@defcomp testcomp1 begin
    var1 = Variable(index=[time])
    par1 = Parameter(index=[time])
    
    function run_timestep(p, v, d, t)
        v.var1[t] = p.par1[t]
    end
end

@defcomp testcomp2 begin
    var1 = Variable(index=[time])
    par1 = Parameter(index=[time])
    
    function run_timestep(p, v, d, t)
        v.var1[t] = p.par1[t]
    end
end

@defcomp testcomp3 begin
    var1 = Variable(index=[time])
    par1 = Parameter(index=[time])
    
    function run_timestep(p, v, d, t)
        v.var1[t] = p.par1[t]
    end
end

#Start building up the model
set_dimension!(my_model, :time, 2015:5:2110)
add_comp!(my_model, testcomp1)

#Testing that you cannot add two components of the same name
@test_throws ErrorException add_comp!(my_model, testcomp1)

# Testing to catch adding component twice
@test_throws ErrorException add_comp!(my_model, testcomp1)

# Testing to catch if before or after does not exist
@test_throws ErrorException add_comp!(my_model, testcomp2, before=:testcomp3)
@test_throws ErrorException add_comp!(my_model, testcomp2, after=:testcomp3)

#Add more components to model
add_comp!(my_model, testcomp2)
add_comp!(my_model, testcomp3)

comps = compdefs(my_model)

#Test compdefs, compdef, compkeys, etc.
@test comps == compdefs(my_model.md)
@test length(comps) == 3
@test compdef(:testcomp3) == [comps...][3]
@test_throws ErrorException compdef(:testcomp4) #this component does not exist
@test [compkeys(my_model.md)...] == [:testcomp1, :testcomp2, :testcomp3]
@test hascomp(my_model.md, :testcomp1) == true && hascomp(my_model.md, :testcomp4) == false

@test compmodule(testcomp3) == :TestComponents
@test compname(testcomp3) == :testcomp3

@test numcomponents(my_model) == 3
add_comp!(my_model, testcomp3, :testcomp3_v2)
@test numcomponents(my_model) == 4

#Test some component dimensions fcns, other dimensions testing in test_dimensions
def = compdef(:testcomp3)
def_dims = dimensions(def)
@test eltype(def_dims) == Mimi.DimensionDef && length(def_dims) == 1
@test [def_dims...][1].name == :time

dump_components() #view all components and their info

#Test reset_compdefs methods
reset_compdefs()
@test length(_compdefs) == 3 #adder, ConnectorCompVector, ConnectorCompMatrix
reset_compdefs(false)
@test length(_compdefs) == 0 


#------------------------------------------------------------------------------
#   Tests for component run periods when resetting the model's time dimension
#------------------------------------------------------------------------------

@defcomp testcomp1 begin
    var1 = Variable(index=[time])
    par1 = Parameter(index=[time])
    
    function run_timestep(p, v, d, t)
        v.var1[t] = p.par1[t]
    end
end

# 1. Test resetting the time dimension without explicit first/last values 

cd = compdef(testcomp1)    
@test cd.first == nothing   # original component definition's first and last values are unset
@test cd.last == nothing

m = Model()
set_dimension!(m, :time, 2001:2005)
add_comp!(m, testcomp1, :C) # Don't set the first and last values here
cd = m.md.comp_defs[:C]     # Get the component definition in the model
@test cd.first == nothing   # First and last values should still be nothing because they were not explicitly set
@test cd.last == nothing

set_param!(m, :C, :par1, zeros(5))
Mimi.build(m)               # Build the model
ci = m.mi.components[:C]    # Get the component instance
@test ci.first == 2001      # The component instance's first and last values should match the model's index
@test ci.last == 2005

set_dimension!(m, :time, 2005:2020) # Reset the time dimension
cd = m.md.comp_defs[:C]     # Get the component definition in the model
@test cd.first == nothing   # First and last values should still be nothing
@test cd.last == nothing

update_param!(m, :par1, zeros(16); update_timesteps=true)
Mimi.build(m)               # Build the model
ci = m.mi.components[:C]    # Get the component instance
@test ci.first == 2005      # The component instance's first and last values should match the model's index
@test ci.last == 2020


# 2. Test resetting the time dimension with explicit first/last values

m = Model()
set_dimension!(m, :time, 2000:2100)
add_comp!(m, testcomp1, :C; first=2010, last=2090)  # Give explicit first and last values for the component
cd = m.md.comp_defs[:C]     # Get the component definition in the model
@test cd.first == 2010      # First and last values are defined in the comp def because they were explicitly given
@test cd.last == 2090

set_param!(m, :C, :par1, zeros(81))
Mimi.build(m)               # Build the model
ci = m.mi.components[:C]    # Get the component instance
@test ci.first == 2010      # The component instance's first and last values are the same as in the comp def
@test ci.last == 2090

set_dimension!(m, :time, 2000:2200) # Reset the time dimension
cd = m.md.comp_defs[:C]     # Get the component definition in the model
@test cd.first == 2010      # First and last values should still be the same
@test cd.last == 2090

Mimi.build(m)               # Build the model
ci = m.mi.components[:C]    # Get the component instance
@test ci.first == 2010      # The component instance's first and last values are the same as the comp def
@test ci.last == 2090


end #module
