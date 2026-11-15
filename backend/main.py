from fastapi import FastAPI, Depends, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from pydantic import BaseModel
from datetime import date
from typing import Optional
import models
from database import SessionLocal, engine

models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="SmartGrocery AI")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],
    allow_methods=["*"],
    allow_headers=["*"],
)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ---------- Pydantic schemas ----------
class GroceryCreate(BaseModel):
    name: str
    quantity: float
    unit: str = "pcs"
    category: Optional[str] = ""
    purchase_date: Optional[date] = None
    expiry_date: date

# ---------- Helpers ----------
def classify_expiry(expiry_date: date) -> str:
    delta = (expiry_date - date.today()).days
    if delta < 0:
        return "expired"
    elif delta <= 2:
        return "urgent"
    elif delta <= 5:
        return "soon"
    return "fresh"

def to_response(g: models.Grocery) -> dict:
    return {
        "id": g.id,
        "name": g.name,
        "quantity": g.quantity,
        "unit": g.unit,
        "category": g.category,
        "purchase_date": g.purchase_date,
        "expiry_date": g.expiry_date,
        "status": classify_expiry(g.expiry_date),
    }

# ---------- Routes ----------
@app.get("/")
def root():
    return {"message": "SmartGrocery AI backend is running"}

@app.post("/groceries/")
def add_grocery(item: GroceryCreate, db: Session = Depends(get_db)):
    db_item = models.Grocery(**item.model_dump())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return to_response(db_item)

@app.get("/groceries/")
def list_groceries(db: Session = Depends(get_db)):
    items = db.query(models.Grocery).all()
    return [to_response(i) for i in items]

@app.delete("/groceries/{item_id}")
def delete_grocery(item_id: int, db: Session = Depends(get_db)):
    item = db.query(models.Grocery).filter(models.Grocery.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    db.delete(item)
    db.commit()
    return {"deleted": item_id}