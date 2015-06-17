#pragma once

#include "Leadwerks.h"

#undef GetFileType

using namespace Leadwerks;

class App
{
public:
	Leadwerks::Window* window;
	Context* context;
	World* world;
	Camera* camera;

	App();
	virtual ~App();

    bool Start();
    bool Loop();
};
