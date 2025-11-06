# Run instructions — OnlineExam_Servlet_Jsp

Short instructions to build and run this NetBeans/Ant Java web application on Windows (PowerShell). The project uses Ant and Java 1.8 and produces `dist/OnlineExam.war`.

Prerequisites
- Java JDK 1.8 installed and `JAVA_HOME` set to the JDK folder.
- Apache Ant installed and `ANT_HOME` added to PATH (ant's `bin` on PATH).
- (For deployment) Apache Tomcat 8/9 installed (or any compatible servlet container).
- MySQL (or the DB the app expects) reachable and the JDBC driver (mysql-connector-java) present in `web/WEB-INF/lib`.

Quick steps (PowerShell)

1) Verify Java and Ant are available

```powershell
java -version
ant -version
```

2) Build a WAR using Ant

From the project root (where `build.xml` is located):

```powershell
# build the distributable WAR
ant dist
```

If successful the WAR will be at `dist/OnlineExam.war`.

3) Deploy to Tomcat (simple copy)

- Copy `dist/OnlineExam.war` into Tomcat's `webapps` folder (e.g. `C:\apache-tomcat-9.0.*/webapps`).
- Start Tomcat with `C:\path\to\tomcat\bin\startup.bat` (or use the Windows service if installed).
- Visit: http://localhost:8080/OnlineExam/ (the WAR name defines the context path). If you want root context, rename to `ROOT.war`.

Alternative: Run with Jetty Runner (no Tomcat install)

1. Download a `jetty-runner` jar (e.g. `jetty-runner-9.4.50.v20221201.jar`).
2. Run:

```powershell
# from project root after ant dist
java -jar C:\path\to\jetty-runner.jar --port 8080 dist/OnlineExam.war
```

Notes & troubleshooting
- Ant not found: ensure Ant is installed and `ant` is on your PATH. On Windows, set `ANT_HOME` and add `%ANT_HOME%\bin` to PATH.
- Java version: this project is configured for Java 1.8 (see `nbproject/project.properties`). Use JDK 8 to avoid compatibility problems.
- Database: `src/java/DB/Db_Connection.java` currently points to a MySQL connection and contains credentials/host. Update the connection string, username and password for your local DB, or make sure the remote DB is reachable. Ensure `mysql-connector-java-x.x.x.jar` is present in `web/WEB-INF/lib` before building/starting.
- If JSP compilation fails during build/run, check `project.properties` settings and that Tomcat libs are reachable.
- If Ant prints errors, capture the terminal output and share it; I can help debug.

Run in NetBeans
- If you use NetBeans: open the project folder and Run (NetBeans will handle Ant/Tomcat if configured). Configure the server in NetBeans Project Properties (Run) to use your local Tomcat.

Security note
- The repository currently contains database credentials in `Db_Connection.java`. Treat these as sensitive; do not publish them. Prefer injecting credentials from environment variables or a non-committed config file.

If you want, I can:
- Try to build it here (I attempted `ant` but it's not installed in this environment).
- Prepare a small PowerShell script to automate install/build/deploy steps on your machine.

Included automation script
- `scripts\build_and_deploy.ps1` — A PowerShell helper that:
	- verifies `java` and `ant` are available,
	- warns if a MySQL JDBC driver isn't present in `web/WEB-INF/lib`,
	- runs `ant dist` to create `dist/OnlineExam.war`, and
	- when called with `-Deploy -TomcatPath 'C:\path\to\tomcat'` copies the WAR to Tomcat's `webapps` and attempts to start Tomcat.

Usage example (from project root):

```powershell
.\scripts\build_and_deploy.ps1            # build only
.\scripts\build_and_deploy.ps1 -Deploy -TomcatPath 'C:\apache-tomcat-9.0.58'  # build and deploy
```

---
Generated on: 2025-11-06
