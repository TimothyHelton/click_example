# PGAdmin Setup
1. From the main directory call `make pgadmin`
    - The default browser will open to `localhost:5000`
1. Enter the **PGAdmin** default user and password.
    - These variable are set in the `envfile`.
1. Click `Add New Server`.
    - General Name: Enter the <project_name>
    - Connection Host: Enter <project_name>_postgres
    - Connection Username and Password: Enter **Postgres** username and password
      from the `envfile`.

