<%@ page session="true" %>
<%@ page
        import="org.openid4java.message.AuthSuccess, org.openid4java.message.DirectError, org.openid4java.message.Message, org.openid4java.message.ParameterList,org.openid4java.server.InMemoryServerAssociationStore,org.openid4java.server.ServerManager" %>
<%
    // There must be NO newlines allowed at beginning or ending of this JSP
    // because the output of this jsp is passed directly
    // (during associate response) to client ParameterList object which barfs on
    // blank lines.
    // README:
    // Set the OPEndpointUrl to the absolute URL of this provider.jsp

    Object o = pageContext.getAttribute("servermanager", PageContext.APPLICATION_SCOPE);
    if (o == null) {
        ServerManager newmgr = new ServerManager();
        newmgr.setSharedAssociations(new InMemoryServerAssociationStore());
        newmgr.setPrivateAssociations(new InMemoryServerAssociationStore());
        newmgr.setOPEndpointUrl(request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + "/simple-openid/provider.jsp");
        pageContext.setAttribute("servermanager", newmgr, PageContext.APPLICATION_SCOPE);

        // The attribute com.mycompany.name1 may not have a value or may have the value null
    }
    ServerManager manager = (ServerManager) pageContext.getAttribute("servermanager", PageContext.APPLICATION_SCOPE);


    ParameterList requestp;

    if ("complete".equals(request.getParameter("_action"))) // Completing the authz and authn process by redirecting here
    {
        requestp = (ParameterList) session.getAttribute("parameterlist"); // On a redirect from the OP authn & authz sequence
    } else {
        requestp = new ParameterList(request.getParameterMap());
    }

    String mode = requestp.hasParameter("openid.mode") ?
                  requestp.getParameterValue("openid.mode") : null;

    Message responsem;
    String responseText;

    if ("associate".equals(mode)) {
        // --- process an association request ---
        responsem = manager.associationResponse(requestp);
        responseText = responsem.keyValueFormEncoding();
    } else if ("checkid_setup".equals(mode)
               || "checkid_immediate".equals(mode)) {
        // interact with the user and obtain data needed to continue
        //List userData = userInteraction(requestp);
        String userSelectedId = null;
        String userSelectedClaimedId = null;
        Boolean authenticatedAndApproved = Boolean.FALSE;

        if ((session.getAttribute("authenticatedAndApproved") == null) ||
            (((Boolean) session.getAttribute("authenticatedAndApproved")) == Boolean.FALSE)) {
            session.setAttribute("parameterlist", requestp);
            response.sendRedirect("provider_authorization.jsp");
        } else {
            userSelectedId = (String) session.getAttribute("openid.claimed_id");
            userSelectedClaimedId = (String) session.getAttribute("openid.identity");
            authenticatedAndApproved = (Boolean) session.getAttribute("authenticatedAndApproved");
            // Remove the parameterlist so this provider can accept requests from elsewhere
            session.removeAttribute("parameterlist");
            session.setAttribute("authenticatedAndApproved", Boolean.FALSE); // Makes you authorize each and every time
        }

        // --- process an authentication request ---
        responsem = manager.authResponse(requestp,
                                         userSelectedId,
                                         userSelectedClaimedId,
                                         authenticatedAndApproved.booleanValue());

        // caller will need to decide which of the following to use:
        // - GET HTTP-redirect to the return_to URL
        // - HTML FORM Redirection
        //responseText = response.wwwFormEncoding();
        if (responsem instanceof AuthSuccess) {
            response.sendRedirect(((AuthSuccess) responsem).getDestinationUrl(true));
            return;
        } else {
            responseText = "<pre>" + responsem.keyValueFormEncoding() + "</pre>";
        }
    } else if ("check_authentication".equals(mode)) {
        // --- processing a verification request ---
        responsem = manager.verify(requestp);
        responseText = responsem.keyValueFormEncoding();
    } else {
        // --- error response ---
        responsem = DirectError.createDirectError("Unknown request");
        responseText = responsem.keyValueFormEncoding();
    }
// make sure there are no empty lines at the end of this file:
// they will end up in direct responses and thus compromise them
%><%=responseText%>