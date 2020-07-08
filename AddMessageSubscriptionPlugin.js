// MySubscriptionPlugin.js
// https://www.graphile.org/postgraphile/make-extend-schema-plugin/
const { makeExtendSchemaPlugin, gql, embed } = require("graphile-utils");

// INFO this is a hacky way to do it, we can assume we will pass in email and message to the arguments.
// but we need ID from the DB...
const newMessageFromContext = (args, _context, _resolveInfo) => {
      return `graphql:message:${context.info.id}`;
};
  
module.exports = makeExtendSchemaPlugin(({ pgSql: sql }) => ({
    typeDefs: gql`
      type MessageSubscriptionPayload {
        # This is populated by our resolver below
        message: Message
  
        # This is returned directly from the PostgreSQL subscription payload (JSON object)
        event: String
      }
  
      extend type Subscription {
        """
        Triggered when the message is added, we still get the information from the graphql query and convert
        it to a URN for the database to use (after the trigger is called).
        """
        messageAdded: MessageSubscriptionPayload @pgSubscription(topic: ${embed(
            newMessageFromContext
        )})
      }
    `,
  
    resolvers: {
      UserSubscriptionPayload: {
        // This method finds the user from the database based on the event
        // published by PostgreSQL.
        //
        // In a future release, we hope to enable you to replace this entire
        // method with a small schema directive above, should you so desire. It's
        // mostly boilerplate.
        async user(
          event,
          _args,
          _context,
          { graphile: { selectGraphQLResultFromTable } }
        ) {
          const rows = await selectGraphQLResultFromTable(
            sql.fragment`app_public.users`,
            (tableAlias, sqlBuilder) => {
              sqlBuilder.where(
                sql.fragment`${tableAlias}.id = ${sql.value(event.subject)}`
              );
            }
          );
          return rows[0];
        },
      },
    },
}));
