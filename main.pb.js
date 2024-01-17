routerPre((next) => {
    return (c) => {
        let token = c.request().header.get("X-Authorization");

        // strip the "Bearer " prefix if available
        // (the schema is not required and it is only for compatibility with the defaults of some HTTP clients)
        if (token.startsWith("Bearer ")) {
            token = token.substring(7);
        }

        if (!token) {
            return next(c)
        }

        try {
            const claims = $security.parseUnverifiedJWT(token)

            if (claims.type == "admin") {
                const admin = $app.dao().findAdminByToken(token, $app.settings().adminAuthToken.secret);
                c.set(claims.type, admin);
            } else if (claims.type == "authRecord") {
                const record = $app.dao().findAuthRecordByToken(token, $app.settings().recordAuthToken.secret);
                c.set(claims.type, record);
            } else {
                throw new Error("unsupported or missing token type:", claims.type);
            }
        } catch (err) {
            $app.logger().debug("invalid or expired token", "token", token, "error", err)
        }
        return next(c)
    }
})
routerAdd("GET", "/_/*", $apis.staticDirectoryHandler("/pb_admin", true))
