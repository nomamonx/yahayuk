local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Vip Script: Mt.Yahayuk",
   LoadingTitle = "Teleport System",
   LoadingSubtitle = "By Mt.Yahayuk",
})

local MainTab = Window:CreateTab("Informasi", 4483362458)

Rayfield:Notify({
   Title = "Script Dimuat",
   Content = "GUI berhasil muncul!",
   Duration = 6.5,
   Image = 4483362458,
})

local Button = MainTab:CreateButton({
   Name = "Tes Tombol",
   Callback = function()
       Rayfield:Notify({
          Title = "Tombol Ditekan",
          Content = "Teleport/fitur lain bisa ditaruh di sini!",
          Duration = 5,
       })
   end,
})
