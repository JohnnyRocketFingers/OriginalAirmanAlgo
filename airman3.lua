-- sudo fceux --frameskip 0 --bpp 8 --nogui 1 --opengl 1 --loadlua ~/airman3.lua --sound 0 "C:\\Users\\Dave\\Desktop\\fceux-2.1.5-win32(1)\\Mega Man 2 (U).nes"
--0x478 to 0x47D = air shooter
--sx = AND(x+255-scrollx,255)

function round(num) 
    if num >= 0 then return math.floor(num+.5) 
    else return math.ceil(num-.5) end
end

ss = savestate.object(1);

cmd = 1;
step = 1

P = 20;
S = 600;
pop = {};
elitism = math.ceil(P/10)
mutation_rate = 0.50


function randomCmd()
	r = math.random()
	if r < 0.25 then
		return "l";
	elseif r < 0.5 then
		return "r";
	elseif r < 0.75 then
		return "a";
	else
		return "b";
	end
end

for i = -1,P do
	pop[i] = {};
	pop[i][0] = 0
	for j = 1,S do
		pop[i][j] = randomCmd();
	end;
end;

gen = 0;
ind = 0;
fit = {};
bestfit = -99
seq = {};

function select(pop)
	C = 0
	P = table.getn(pop)
	Cmax = P*(P+1)/2
	r = math.random(0,Cmax)
	--print(string.format("%d %d %d",P,Cmax,r))
	for i = 1,P do
		C = C + (P-i+1)
		--print(string.format("%d %f",C,r))
		if r <= C then
			--print(string.format("foi %d",i))
			return i
		end
	end	
end

function mutate(pop)
	P = table.getn(pop)
	for i = elitism+1,P do
		s = table.getn(pop[i]);
		--m = (i - 1) / (P - 1)
		m = mutation_rate
		for j = 1,s do
			if math.random() < m then--*(1-pop[-1][j]/pop[-1][0]) then
				pop[i][j] = randomCmd()
			end
		end
	end
	return pop			
end

function crossover(pop)
	P = table.getn(pop)
	newpop = {}
	for i = 1,elitism do
		newpop[i] = {}
		newpop[i][0] = 0
		s = table.getn(pop[i])
		for j = 1,s do
			newpop[i][j] = pop[i][j]
		end
	end
	for i = elitism+1,P do
		newpop[i] = {}
		newpop[i][0] = 0
		c1 = select(pop)
		c2 = select(pop)
		s = table.getn(pop[i])
		p = math.random(1,s)
		for j = 1,p do
			newpop[i][j] = pop[c1][j]
		end
		for j = p+1,s do
			newpop[i][j] = pop[c2][j]
		end
	end
	return newpop
end
    
function dna2seq(dna)
	s = table.getn(dna);
	seq = {};
	for i = 1,s do
		seq[i] = dna[i]
	end
	return seq;
end

function cmd2inp(cmd)
	A = false;
	B = false;
	left = false;
	right = false;
	
	if string.find(cmd,"a") ~= nil then
		A = true;
	end
	if string.find(cmd,"b") ~= nil then
		B = true;
	end
	if string.find(cmd,"l") ~= nil then
		left = true;
	end
	if string.find(cmd,"r") ~= nil then
		right = true;
	end
	
	return {up=false,down=false,start=false,select=false,left=left,right=right,A=A,B=B};
end

function comp(w1,w2)
    if w1[0] > w2[0] then
        return true
    end
end

function complexity(seq)
	s = table.getn(seq)
	c = 0
	for i = 1,s do
		c = c + string.len(seq[i])
	end
	return c
end
        
emu.speedmode("maximum")
--emu.setrenderplanes(false, false)



math.randomseed(1)
newsolution = false

--sspath = "C:\\Users\\Dave\\Desktop\\fceux-2.1.5-win32(1)\\screenshots\\"
sspath = "C:\\Users\\Dave\\Desktop\\fceux-2.1.5-win32(1)\\screenshots\\"

while true do
	hp = memory.readbyte(0x06C0);
	bosshp = memory.readbyte(0x06C1);
	gui.text(10,200,string.format("Generation: %d Best Fitness: %.5f\n Current Individual: %d/%d",gen,bestfit,ind,P))
	if newsolution then
		--gui.savescreenshotas(string.format("%sg%05d-f%f-s%04d.png",sspath,gen-1,bestfit,step-1))
	end
	if hp == 0 or bosshp == 0 then
		emu.speedmode("maximum")
		newsolution = false
		--emu.setrenderplanes(false, false)
		if ind > 0 then
			--co = complexity(dna2seq(pop[ind]))
			--print(string.format("%d",co))
			pop[ind][0] = (hp - bosshp) + 100*((28-bosshp) - (28-hp))/step -- 0.00001*co;
		end
		ind = ind + 1;
		if ind > P then
			ind = 1;
			gen = gen + 1;
			--Sort
			table.sort(pop,comp)
			mean = 0
			for i = 1,P do
				mean = mean + pop[i][0]
			end
			mean = mean / P
			if pop[1][0] > bestfit then
				bestfit = pop[1][0]
				--emu.speedmode("normal")
				print(string.format("Gen.: %d Best Fitness: %f Mean: %f",gen-1,pop[1][0],mean))
				newsolution = true
				--emu.setrenderplanes(true, true)
			end


			--Mutate
			mutate(pop)
			--Crossover
			pop = crossover(pop)
			
		end
		seq = dna2seq(pop[ind]);
		cmd = 1
		step = 1
		savestate.load(ss);
	end
	if gen > 0 and ind == 1 then
		--emu.message("HP: " .. hp .. "x" .. bosshp .. " Gen.: " .. gen .. " Indiv.: " .. ind .. "/" .. P .. " Best Fit.: " .. string.format("%.3f",bestfit));
	else
		--emu.message("HP: " .. hp .. "x" .. bosshp .. " Gen.: " .. gen .. " Indiv.: " .. ind .. "/" .. P .. " cmd(" .. cmd .. "): " .. seq[cmd]);
	end
	joypad.set(1, cmd2inp(seq[cmd]));
	if math.mod(step,2) == 0 then
		cmd = cmd + 1;
	end
	if cmd > table.getn(seq) then
		cmd = 1;
	end
	step = step + 1
	emu.frameadvance();
end




