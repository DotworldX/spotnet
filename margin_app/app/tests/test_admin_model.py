import pytest
from sqlalchemy import select
from app.models.admin import Admin

@pytest.mark.asyncio
async def test_create_admin(db_connector):
    """
    Test creating an admin instance and retrieving it from the database.
    """

    async with db_connector.get_session() as session:
        
        admin = Admin(
            email="admin@example.com",
            name="Test Admin",
            is_super_admin=True,
            password="hashedpassword123"
        )
        session.add(admin)
        await session.commit()
        
    
        result = await session.execute(
            select(Admin).filter_by(email="admin@example.com")
        )
        retrieved = result.scalar_one_or_none()
        assert retrieved is not None, "Admin instance should exist in the database."
        assert retrieved.name == "Test Admin", "Admin name should match the created value."
        assert retrieved.is_super_admin is True, "Admin super status should be True."


@pytest.mark.asyncio
async def test_unique_email_constraint(db_connector):
    """
    Test that the unique email constraint on the Admin model prevents duplicate emails.
    """
    async with db_connector.get_session() as session:
        admin1 = Admin(
            email="unique@example.com",
            name="Admin One",
            is_super_admin=False,
            password="hashedpassword123"
        )
        admin2 = Admin(
            email="unique@example.com",
            name="Admin Two",
            is_super_admin=False,
            password="hashedpassword456"
        )
        session.add(admin1)
        await session.commit()
        
        session.add(admin2)

        with pytest.raises(Exception):
            await session.commit()
