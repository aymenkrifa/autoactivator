from fastapi import FastAPI
from fastapi.responses import FileResponse
import uvicorn

app = FastAPI()

@app.get("/script")
async def get_script():
    return FileResponse("../activator.sh")

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
