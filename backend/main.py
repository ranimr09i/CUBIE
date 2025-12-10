from fastapi import FastAPI
from db import init_db
from users import users_router
from children import children_router
from stories import stories_router
from chat import chat_router
from audio import audio_router
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles


app = FastAPI(title="CUBIE Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  
    allow_credentials=True,
    allow_methods=["*"], 
    allow_headers=["*"],  
)

init_db()

app.include_router(users_router, prefix="/users", tags=["Users"])
app.include_router(children_router, prefix="/children", tags=["Children"])
app.include_router(stories_router, prefix="/stories", tags=["Stories"])
app.include_router(chat_router, prefix="/chat", tags=["Chat"])
app.include_router(audio_router, prefix="/audio", tags=["Audio"])
app.mount("/audio_files", StaticFiles(directory="audio_files"), name="audio")