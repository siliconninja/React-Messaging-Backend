module.exports = {
    options: {
      connection: "postgres://messagesdb_user:messagesdb_user@localhost/messagesdb",
      ownerConnectionString: "postgres://db_owner:db_owner_pass@localhost/messagesdb"
    //   schema: ["myApp", "myAppPrivate"],
    //   jwtSecret: "myJwtSecret",
    //   defaultRole: "myapp_anonymous",
    //   jwtTokenIdentifier: "myApp.jwt_token",
    //   watch: true,
    },
  };