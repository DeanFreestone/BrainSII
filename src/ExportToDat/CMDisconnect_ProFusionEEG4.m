function CMDisconnect_ProFusionEEG4

global gIStudy DataReader

if( isinterface( DataReader ) )
    Events = DataReader.eventlisteners;
    if( ~isempty(Events) )
        DataReader.unregisterallevents()
        disp('Unregistered all DataReader events.');
    end
    DataReader.release;
    disp('Released DataReader interface.');
end

if( iscom( gIStudy ) )
    gIStudy.delete;
    disp('Deleted the gIStudy COM server.');
end