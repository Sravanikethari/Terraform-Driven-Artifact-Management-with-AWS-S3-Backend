# 1. Install Java 17 (Amazon Corretto)
yum install -y java-17-amazon-corretto-devel

# 2. Download latest Tomcat 9
wget https://downloads.apache.org/tomcat/tomcat-9/v9.0.112/bin/apache-tomcat-9.0.112.tar.gz

# 3. Extract
tar -xzf apache-tomcat-9.0.112.tar.gz

# 4. Move to /opt (standard location)
mv apache-tomcat-9.0.112 /opt/tomcat

# 5. Create tomcat user
groupadd -r tomcat
useradd -r -g tomcat -s /bin/false -d /opt/tomcat tomcat
chown -R tomcat:tomcat /opt/tomcat

# 6. Fix tomcat-users.xml (add user OUTSIDE comments)
cat > /opt/tomcat/conf/tomcat-users.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<tomcat-users xmlns="http://tomcat.apache.org/xml"
              xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
              xsi:schemaLocation="http://tomcat.apache.org/xml tomcat-users.xsd"
              version="1.0">
  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <user username="tomcat" password="admin@123" roles="manager-gui,manager-script"/>
</tomcat-users>
EOF

# 7. Allow remote access to Manager (comment out IP restriction)
sed -i 's/<Valve className="org.apache.catalina.valves.RemoteAddrValve"/<!-- & -->/' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i 's/<\/Valve>/<\/Valve> -->/' /opt/tomcat/webapps/manager/META-INF/context.xml

# 8. Create systemd service
cat > /etc/systemd/system/tomcat.service << 'EOF'
[Unit]
Description=Apache Tomcat 9
After=network.target

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 9. Enable and start Tomcat
systemctl daemon-reload
systemctl enable tomcat
systemctl start tomcat

# 10. Open firewall
firewall-cmd --add-port=8080/tcp --permanent
firewall-cmd --reload

# 11. Done!
echo "Tomcat installed! Access:"
echo "   Web: http://$(curl -s ifconfig.me):8080"
echo "   Manager: http://$(curl -s ifconfig.me):8080/manager/html"
echo "   User: tomcat | Pass: admin@123"
