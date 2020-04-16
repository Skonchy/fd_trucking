-- This script was authored poorly by Jake

-- 1) draw circles on ground where we want people to pick up / deliver trailers to
-- 2) populate circles with contracts that reset after x minutes
-- 3) when contract selected spawn trailer and mark map with delivery location
-- 4) detach trailer in delivery zone get paid and despawn the trailer

--stop people from being a cunt and taking every job smile

ESX=nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
    end
end)

-- Citizen.CreateThread(function()
--     while true do
--         Citizen.Wait(1000)
--         print(GetEntityCoords(PlayerPedId()).." "..GetEntityHeading(PlayerPedId()))
--     end
-- end)

local zones = {
    docks1 = vector3(-126.441,-2416.368,5.635);
    docks2 = vector3(72.188, -2723.332, 5.640);
    docks3 = vector3(767.764, -2976.236, 5.436);
    elysian = vector3(1732.646, -1572.726, 112.251);
    mine = vector3(2691.211, 2749.734, 37.1);
    hdepot = vector3(2668.795, 3526.945, 52);
    hlabs = vector3(3473.114, 3678.832, 33.5);
    chicken = vector3(11.735, 6276.994, 31.052);
    salvage = vector3(-189.377, 6290.231, 31.471);
}

local trailers ={
    elysian = vector4(1716.545, -1569.526, 112.620,180);
    docks1 = vector4(-148.81,-2416.43,6.070,182.84);
    docks2 = vector4(86.71, -2706.15, 6.3,169.38);
    docks3 = vector4(760.99, -2951, 5.8,178.94);
    mine = vector4(2713.211, 2761.734, 36.684,125.01);
    hdepot = vector4(2674.1, 3518.9, 52.71,337.01);
    hlabs = vector4(3454.095, 3681.153, 33.029,353.656);
    chicken = vector4(41.709, 6291.526, 31.253,117.127);
    salvage = vector4(-168.399, 6273.351, 31.559,45.110);
}

local hasAlreadyEnteredMarker, isInMarker, where

local jobs = {}
local activejob,deliveryblip
local trailerplate, trailer

function openContractMenu(start)
    ESX.UI.Menu.CloseAll()
    local elements = {{label='Abandon Current Job', value='quit_job'}}
    for k,v in pairs(jobs) do
        if v[1] == start then
            table.insert(elements,{label='Dest: '..v[2]..' Type: '..v[3]..' Pay: '..v[4]..'',start=v[1],dest=v[2],type=v[3],pay=v[4], value='take_job'})
        end
    end
    ESX.UI.Menu.Open('default',GetCurrentResourceName(),'contracts',{
        title = 'Trucking',
        align = 'center',
        elements = elements
    }, function(data,menu)
        local action = data.current.value
        if action == 'take_job' and activejob == nil then
            activejob={
                start=data.current.start,
                dest=data.current.dest,
                type=data.current.type,
                pay=data.current.pay,
        }
            spawnTrailer(data.current.start,data.current.dest,data.current.type)
            for k,v in pairs(elements) do
                if data.current.label == elements[k].label then
                    table.remove(elements,k)
                    break
                end
            end

            for k,v in pairs(jobs) do
                if v[2]==data.current.dest and v[3]==data.current.type and v[4]==data.current.pay then
                    table.remove(jobs,k)
                end
            end
        elseif action == 'quit_job' then
            activejob = nil
            DeleteVehicle(trailer)
            RemoveBlip(deliveryblip)
        else
            TriggerEvent('esx:showNotification',"You already have an active delivery")
        end
        menu.close()
    end)

end

function tablelength(T)
    local count = 0
    for _ in pairs(T) do 
        count = count + 1 
    end
    return count
end

function spawnTrailer(start,dest,type)
    local hash
    if type=="Liquid" then
        hash=GetHashKey("tanker2")
    else
        local random= math.random(6)
        if random == 1 then
            hash=GetHashKey("trailerlogs")
        elseif random == 2 then
            hash=GetHashKey("docktrailer")
        elseif random == 3 then
            hash=GetHashKey("trailers")
        elseif random == 4 then
            hash=GetHashKey("tr4")
        elseif random == 5 then
            hash=GetHashKey("trailers4")
        else
            hash=GetHashKey("trailers3")
        end
    end
    
    RequestModel(hash)
    while not HasModelLoaded(hash) do
        RequestModel(hash)
        Citizen.Wait(0)
    end
    local truck = GetVehiclePedIsIn(GetPlayerPed(-1),false)
    trailer = CreateVehicle(hash, trailers[start].x, trailers[start].y, trailers[start].z, trailers[start].w, true, false)
    SetEntityAsMissionEntity(trailer, true, true)
    --AttachVehicleToTrailer(truck, trailer, 1.1)
    trailerplate=GetVehicleNumberPlateText(trailer)

    --set delivery
    deliveryblip=AddBlipForCoord(zones[dest].x,zones[dest].y,zones[dest].z)
    SetBlipSprite(deliveryblip, 304)
    SetBlipDisplay(deliveryblip, 4)
    SetBlipScale(deliveryblip, 1.0)
    SetBlipColour(deliveryblip, 5)
    SetBlipAsShortRange(deliveryblip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Delivery point")
    EndTextCommandSetBlipName(deliveryblip)
  
    SetBlipRoute(deliveryblip, true) --Add the route to the blip
end

function deliverTrailer()
    local truck = GetVehiclePedIsIn(GetPlayerPed(-1),false)
    local isTrailer, trailerid = GetVehicleTrailerVehicle(truck)
    current_trailer=GetVehicleNumberPlateText(trailerid)
    if current_trailer == trailerplate then
        local health = GetVehicleBodyHealth(trailerid)
        local pay = activejob.pay
        if health < 900 then
            pay = pay*(health/1500)
            TriggerEvent('esx:showNotification', "Trailer was damaged so payment was reduced")
            if health < 100 then
                pay=0
                TriggerEvent('esx:showNotification', "Trailer was too damaged so no payment received")
            end
        end
        TriggerServerEvent('fd_trucking:pay',pay)
        DeleteVehicle(trailerid)
        RemoveBlip(deliveryblip)
        activejob=nil
    else
        print("Attempted to deliver a wrong trailer")
    end

end

local zoneLength = tablelength(zones)

function createNewJob(start)
    local random = math.random(zoneLength)
    local dest
    local i=1
    for k,v in pairs(zones) do
        if i<=random then
            dest=k
            i=i+1
        else
            break
        end
    end
    local rand2 = math.random(2)
    local type
    if rand2 == 1 then
        type="Freight"
    else
        type="Liquid"
    end
    local pay = math.ceil(Vdist(zones[dest],zones[start])*0.10)
    if type == "Liquid" then
        pay = math.ceil(pay*1.2)
    end
    if start ~= dest then
        table.insert(jobs,{start, dest, type, pay})
    end
end

Citizen.CreateThread(function()
    while true do
        while tablelength(jobs)<50 do
            random=math.random(zoneLength)
            local start
            local i=1
            for k,v in pairs(zones) do
                if i<=random then
                    start=k
                    i=i+1
                else
                    break
                end
            end
            createNewJob(start)
        end
        Citizen.Wait(600000)
    end
end)

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local playerCoords = GetEntityCoords(PlayerPedId())
        isInMarker=false
        local distance
        for k,v in pairs(zones) do
            distance = Vdist(playerCoords.x,playerCoords.y,playerCoords.z, v.x,v.y,v.z)
            --print(k.." "..distance)
            if distance < 500 then
                DrawMarker(39, v.x,v.y,v.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 0, 255, 0, 100, false, true, 2, true, false, false, false)
                if distance < 5 then
                    isInMarker = true
                    if activejob~=nil then
                        if k == activejob.dest then
                            deliverTrailer()
                        end
                    else
                    ESX.ShowNotification("Press E to Interact")
                    where = k
                    end
                end
            end
        end
    end
end)

--Controls
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local vehicle = GetVehiclePedIsIn(GetPlayerPed(-1),false)
        local name = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
        if isInMarker and IsControlJustPressed(0,38) then
            if name == 'PHANTOM' or name == 'PACKER' or name == 'PHANTOM3' or name == 'HAULER' then
                openContractMenu(where)
            else
                print("Yes hello little leg man")
                TriggerEvent('esx:showNotification',"Come back with a semi")
            end
        end

    end
end)

function dump(o)
    if type(o) == 'table' then
       local s = '{ '
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} '
    else
       return tostring(o)
    end
 end