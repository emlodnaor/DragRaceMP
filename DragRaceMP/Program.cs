// See https://aka.ms/new-console-template for more information
using System.IO.Compression;
using System.Text;

var clientZipName = "bonDragRace.zip";
Console.WriteLine("Hello, World!");
if (File.Exists(clientZipName)) File.Delete(clientZipName);
ZipFile.CreateFromDirectory("Resources\\Client\\", clientZipName, CompressionLevel.SmallestSize, false, Encoding.UTF8);
if (!Directory.Exists("Server\\Resources\\Client\\")) Directory.CreateDirectory("Server\\Resources\\Client\\");
File.Copy("bonDragRace.zip", "Server\\Resources\\Client\\" + "bonDragRace.zip", true);

if (!Directory.Exists("Server\\Resources\\Server\\BonDragRace\\")) Directory.CreateDirectory("Server\\Resources\\Server\\BonDragRace\\");
File.Copy("Resources\\Server\\BonDragRace\\DragRaceServer.lua", "Server\\Resources\\Server\\BonDragRace\\DragRaceServer.lua");
