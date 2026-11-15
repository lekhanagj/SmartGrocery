from sqlalchemy import Column, Integer, String, Float, Date
from database import Base

class Grocery(Base):
    __tablename__ = "groceries"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, nullable=False, index=True)
    quantity = Column(Float, nullable=False, default=0)
    unit = Column(String, default="pcs")
    category = Column(String, default="")
    purchase_date = Column(Date)
    expiry_date = Column(Date, nullable=False)