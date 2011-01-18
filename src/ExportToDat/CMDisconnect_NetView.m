function CMDisconnect_NetView

global gServer % gInterface gInterfaceExt

% Somehow unregistering the interface events and releasing the interfaces
% causes ProFusionEEG4 to crash during real time recordings!!!
%--------------------------------------------------------------------------
% if( isinterface( gInterface ) )
%     Events = gInterface.eventlisteners;
%     if( ~isempty(Events) )
%         gInterface.unregisterallevents()
%         disp('Unregistered all NetView interface events.');
%     end
%     gInterface.release;
%     disp('Released NetView interface.');
% end
% 
% if( isinterface( gInterfaceExt ) )
%     Events = gInterfaceExt.eventlisteners;
%     if( ~isempty(Events) )
%         gInterfaceExt.unregisterallevents()
%         disp('Unregistered all NetView interface extensions events.');
%     end
%     gInterfaceExt.release;
%     disp('Released NetView interface extensions.');
% end
%--------------------------------------------------------------------------

if( iscom( gServer ) )
    Events = gServer.eventlisteners;
    if( ~isempty(Events) )
        gServer.unregisterallevents;
        disp('Unregistered all NetView COM server events.');
    end
    gServer.delete;
    disp('Released all interfaces and deleted the NetView COM server.');
end