from sqlalchemy import Column, Integer, ForeignKey, UniqueConstraint
from app.db.session import Base


class CompanyMember(Base):
    __tablename__ = 'company_members'
    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('users.id'), nullable=False)
    company_id = Column(Integer, ForeignKey('company_placements.id'), nullable=False)
    __table_args__ = (UniqueConstraint('user_id', 'company_id'),)
