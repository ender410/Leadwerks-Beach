#include "App.h"

using namespace Leadwerks;

App::App() : window(NULL), context(NULL), world(NULL), camera(NULL) {}

App::~App() { delete world; delete window; }

bool App::Start()
{
	int stacksize = Interpreter::GetStackSize();

	//Get the global error handler function
	int errorfunctionindex = 0;
#ifdef DEBUG
	Interpreter::GetGlobal("LuaErrorHandler");
	errorfunctionindex = Interpreter::GetStackSize();
#endif

	//Create new table and assign it to the global variable "App"
	Interpreter::NewTable();
	Interpreter::SetGlobal("App");
	
	std::string scriptpath = "Scripts/Main.lua";
	if (FileSystem::GetFileType("Scripts/App.Lua") == 1) scriptpath = "Scripts/App.Lua";

	//Invoke the start script
	if (!Interpreter::ExecuteFile(scriptpath))
	{
		System::Print("Error: Failed to execute script \"" + scriptpath + "\".");
		return false;
	}

	//Call the App:Start() function
	Interpreter::GetGlobal("App");
	if (Interpreter::IsTable())
	{
		Interpreter::PushString("Start");
		Interpreter::GetTable();
		if (Interpreter::IsFunction())
		{
			Interpreter::PushValue(-2);//Push the app table onto the stack as "self"
#ifdef DEBUG
			errorfunctionindex = -(Interpreter::GetStackSize() - errorfunctionindex + 1);
#endif
			if (!Interpreter::Invoke(1, 1, errorfunctionindex)) return false;
			if (Interpreter::IsBool())
			{
				if (!Interpreter::ToBool()) return false;
			}
			else
			{
				return false;
			}
		}
	}

	//Restore the stack size
	Interpreter::SetStackSize(stacksize);

	return true;
}

bool App::Loop()
{
	//Get the stack size
	int stacksize = Interpreter::GetStackSize();

	//Get the global error handler function
	int errorfunctionindex = 0;
#ifdef DEBUG
	Interpreter::GetGlobal("LuaErrorHandler");
	errorfunctionindex = Interpreter::GetStackSize();
#endif

	//Call the App:Start() function
	Interpreter::GetGlobal("App");
	if (Interpreter::IsTable())
	{
		Interpreter::PushString("Loop");
		Interpreter::GetTable();
		if (Interpreter::IsFunction())
		{
			Interpreter::PushValue(-2);//Push the app table onto the stack as "self"
#ifdef DEBUG
			errorfunctionindex = -(Interpreter::GetStackSize() - errorfunctionindex + 1);
#endif
			if (!Interpreter::Invoke(1, 1, errorfunctionindex))
			{
				System::Print("Error: Script function App:Loop() was not successfully invoked.");
				Interpreter::SetStackSize(stacksize);
				return false;
			}
			if (Interpreter::IsBool())
			{
				if (!Interpreter::ToBool())
				{
					Interpreter::SetStackSize(stacksize);
					return false;
				}
			}
			else
			{
				Interpreter::SetStackSize(stacksize);
				return false;
			}
		}
		else
		{
			//System::Print("Error: App:Loop() function not found.");
			Interpreter::SetStackSize(stacksize);
			return false;
		}
	}
	else
	{
		//System::Print("Error: App table not found.");
		Interpreter::SetStackSize(stacksize);
		return false;
	}

	//Restore the stack size
	Interpreter::SetStackSize(stacksize);

	return true;
}
