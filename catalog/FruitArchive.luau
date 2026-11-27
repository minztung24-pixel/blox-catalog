local FruitVisuals = require(script.Parent.FruitVisuals)
local Http=game:GetService("HttpService")
local FruitArchive={}
local indexPath="blox-catalog-captured-fruits-v1.json"
local backupPath="blox-catalog-captured-fruits-v1.backup.json"
local function physical(item)
    return type(item.id)=="string"and item.id:match("^%d+$")and (item.category=="Fruits"or item.isPhysicalFruit)
end
local function validEntry(id,entry)
    return type(id)=="string"and id:match("^%d+$")and type(entry)=="table"
        and type(entry.file)=="string"and entry.file:match("^blox%-catalog%-captured%-fruit%-"..id.."%-%x+%.rbxm$")
        and entry.metadata==entry.file:gsub("%.rbxm$",".json")
end
function FruitArchive.new(ops,onResult)
    ops=ops or {exists=isfile,read=readfile,write=writefile,uri=getcustomasset,
        objects=function(uri)return game:GetObjects(uri)end,
        export=typeof(saveinstance)=="function"and function(root,path)
            saveinstance(root,{FileName=path,Decompile=false,ShowStatus=false})
        end}
    local enabled=typeof(ops.exists)=="function"and typeof(ops.read)=="function"and typeof(ops.uri)=="function"and typeof(ops.objects)=="function"
    local archive={entries={},errors={},closed=false,pending={}}
    local function readIndex(path)
        local ok,result=pcall(function()
            if not ops.exists(path)then return end
            local bytes=ops.read(path);assert(#bytes<=128*1024,"Capture index too large")
            local index=Http:JSONDecode(bytes)
            assert(index.schemaVersion==1 and type(index.entries)=="table","Invalid capture index")
            local count=0
            for id,entry in pairs(index.entries)do
                count+=1;assert(count<=100 and validEntry(id,entry),"Invalid capture index entry")
            end
            return index.entries
        end)
        return ok and result or nil
    end
    if enabled then archive.entries=readIndex(indexPath)or readIndex(backupPath)or {}end
    function archive:available(item)
        if not enabled or self.closed or not physical(item)or self.errors[item.id]then return false end
        local entry=self.entries[item.id]
        if not validEntry(item.id,entry)then return false end
        local ok,exists=pcall(function()return ops.exists(entry.file)and ops.exists(entry.metadata)end)
        return ok and exists or false
    end
    local function readModel(item,entry,metadata)
        local objects,model
        local ok,message=pcall(function()
            assert(validEntry(item.id,entry),"Invalid capture path")
            local bytes=ops.read(entry.file);assert(#bytes>0 and #bytes<=8*1024*1024,"Invalid capture size")
            if not metadata then
                local json=ops.read(entry.metadata);assert(#json<=2*1024*1024,"Capture metadata too large")
                metadata=Http:JSONDecode(json)
            end
            objects=ops.objects(ops.uri(entry.file))
            assert(type(objects)=="table"and #objects==1 and typeof(objects[1])=="Instance"and objects[1]:IsA("Tool"),"Expected one captured Tool")
            model=objects[1]
            assert(not model:FindFirstChildWhichIsA("LuaSourceContainer",true)
                and not model:FindFirstChildWhichIsA("RemoteEvent",true)
                and not model:FindFirstChildWhichIsA("UnreliableRemoteEvent",true)
                and not model:FindFirstChildWhichIsA("RemoteFunction",true),"Captured model contains executable objects")
            FruitVisuals.restore(model,metadata,item.id)
            assert(not archive.closed,"Capture archive closed while loading")
        end)
        if not ok then
            if type(objects)=="table"then for _,node in pairs(objects)do if typeof(node)=="Instance"then node:Destroy()end end end
            return nil,tostring(message)
        end
        return model
    end
    function archive:load(item)
        if not self:available(item)then return nil end
        local model,message=readModel(item,self.entries[item.id])
        if not model then self.errors[item.id]=message end
        return model,message
    end
    function archive:save(item,source)
        if not enabled or self.closed or not physical(item)or typeof(ops.export)~="function"or typeof(ops.write)~="function"then return nil,"Model exporter unavailable"end
        local copy,verified
        local ok,message=pcall(function()
            assert(source:IsA("Tool")and source:GetAttribute("BloxCatalogOwned")and tostring(source:GetAttribute("ItemId"))==item.id,"Export only a sanitized physical capture")
            assert(#source:GetDescendants()<=3000 and (source:FindFirstChildWhichIsA("MeshPart",true)or source:FindFirstChildWhichIsA("SpecialMesh",true)),"Capture has no mesh yet")
            copy=source:Clone()
            local all={copy}
            for _,node in ipairs(copy:GetDescendants())do table.insert(all,node)end
            for _,node in ipairs(all)do
                for key in pairs(node:GetAttributes())do node:SetAttribute(key,nil)end
                if node:IsA("ValueBase")or node:IsA("TouchTransmitter")then node:Destroy()end
            end
            copy:SetAttribute("ItemId",tonumber(item.id));copy:SetAttribute("BloxCatalogOwned",true)
            local metadata=FruitVisuals.metadata(copy)
            local json=Http:JSONEncode(metadata);assert(#json<=2*1024*1024,"Capture metadata too large")
            local file="blox-catalog-captured-fruit-"..item.id.."-"..Http:GenerateGUID(false):gsub("-","")..".rbxm"
            local entry={file=file,metadata=file:gsub("%.rbxm$",".json")}
            assert(not ops.exists(entry.file)and not ops.exists(entry.metadata),"Capture already exists")
            ops.export(copy,entry.file)
            local deadline=os.clock()+10
            while not ops.exists(entry.file)and not self.closed and os.clock()<deadline do task.wait(.1)end
            assert(not self.closed and ops.exists(entry.file),"Capture export did not finish")
            verified=assert(readModel(item,entry,metadata))
            ops.write(entry.metadata,json)
            assert(ops.read(entry.metadata)==json,"Capture metadata write failed")
            local entries=table.clone(self.entries);entries[item.id]=entry
            local index=Http:JSONEncode({schemaVersion=1,entries=entries})
            -- Keep the last validated index if an interrupted write damages the current one.
            local old=readIndex(indexPath)
            if old then ops.write(backupPath,Http:JSONEncode({schemaVersion=1,entries=old}))end
            assert(not self.closed,"Capture archive closed before commit")
            ops.write(indexPath,index)
            assert(ops.read(indexPath)==index,"Capture index write failed")
            self.entries=entries;self.errors[item.id]=nil
        end)
        if copy then copy:Destroy()end
        if verified then verified:Destroy()end
        if not ok then return nil,tostring(message)end
        return true
    end
    function archive:enqueue(item,source)
        if self.closed or not enabled or typeof(ops.export)~="function"then return end
        local previous=self.pending[item.id]
        if previous then previous:Destroy()end
        self.pending[item.id]=source:Clone()
        if self.worker then return end
        self.worker=task.delay(.5,function()
            while not self.closed do
                local id,copy=next(self.pending)
                if not id then break end
                self.pending[id]=nil
                local ok,message=self:save({id=id,category="Fruits"},copy)
                copy:Destroy()
                if not self.closed and onResult then onResult(id,ok,message)end
            end
            self.worker=nil
        end)
    end
    function archive:clearErrors()table.clear(self.errors)end
    function archive:close()
        self.closed=true
        for _,copy in pairs(self.pending)do copy:Destroy()end
        table.clear(self.pending)
    end
    return archive
end
return FruitArchive
