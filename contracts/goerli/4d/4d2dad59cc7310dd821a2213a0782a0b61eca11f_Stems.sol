// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Stems {

    enum StemType {
        VOCALS,
        INSTRUMENTS,
        DRUMS,
        BASS,
        GUITAR
    }

    struct Song {
        string name;
        string artist;
        int16 bpm;
        int16 bpmDecimal;
        string key; // A Major, B Minor etc
    }

    struct Stem {
        string uri; // location of sample
        uint16 duration; // duration in ms
        bool isLoop; // is it a loop or not-- if not, its a full-length stem
    }

    uint256 private songIdCounter=0;
    uint256 private configIdCounter=0;
    uint256 private stemIdCounter=0;

    mapping (uint256 => Song) songs; // by id
    mapping (uint256 => Stem) stems; // by id 
    mapping (uint256 => uint256[]) songConfigurations; // by id

    // mappings from entityId -> entity(/ies)
    mapping (uint256 => uint256[]) songToStems; // song -> all stemIds
    mapping (uint256 => StemType[]) stemToTypes; // stem -> types
    mapping (uint256 => uint256) defaultSongConfigurations; // songId -> configId
    mapping (uint256 => uint256) stemToSong; // stemId => songId

    event NewSong(uint256 songId, string name, string artist, int16 bpm, int16 bpmDecimal, string key);
    event NewStem(uint256 songId, uint256 stemId, string uri, uint16 duration, bool isLoop);
    event NewStemType(uint256 stemId, StemType stemType);
    event NewDefaultSongConfiguration(uint256 songId, uint256 configId);
    event SongConfigurationStem(uint256 configId, uint256 stemId);
    event StemDeleted(uint256 stemId);

    

    function newSong(
        string memory title,
        string  memory artist,
        string[] memory stemURIs,
        StemType[][] memory stemTypes,
        bool[] calldata isLoops,
        uint16[] calldata durations,
        int16  bpm,
        int16  bpmDecimal,
        string memory key)  public {
        
        uint256 songId = songIdCounter++;
        songs[songId] = Song(
            title,
            artist,
            bpm,
            bpmDecimal,
            key
        );

        emit NewSong(songId, title, artist, bpm, bpmDecimal, key);
       
        newStems(songId, stemURIs, stemTypes, durations, isLoops);

        uint256 configId = configIdCounter++;
        defaultSongConfigurations[songId] = configId;
        emit NewDefaultSongConfiguration(songId, configId);

        for (uint i=0; i < stemURIs.length; i++) {
            uint256 stemId = songToStems[songId][i];
            emit SongConfigurationStem(configId, stemId);
            songConfigurations[configId].push(stemId);
        }    
    }

    /**
    * Bulk upload new stems to a song. Does not set the configuration, 
    * simply adds to the pool of stems around a song
    */
    function newStems(
        uint256 songId, 
        string[] memory stemURIs, 
        StemType[][] memory stemTypes, 
        uint16[] memory durations,
        bool[] memory isLoops) 
    public {
        for (uint i=0; i < stemURIs.length; i++) {
            uint256 stemId = stemIdCounter++;
            stems[stemId] = Stem(
                stemURIs[i],
                durations[i],
                isLoops[i]
            );

            stemToSong[stemId] = songId;
            stemToTypes[stemId] = stemTypes[i];
            songToStems[songId].push(stemId);
            emit NewStem(songId, stemId, stemURIs[i], durations[i], isLoops[i]);
             for (uint j=0; j < stemTypes[i].length; j++) {
                emit NewStemType(stemId, stemTypes[i][j]);
            }
        }
    }

    /**
    * Creates a new default configuration of stems for a song
    */
    function updateSongConfiguration(
        uint256 songId, 
        uint256 [] memory stemIds) 
    public {
        uint256 configId = configIdCounter++;
        defaultSongConfigurations[songId] = configId;

        for (uint i=0; i < stemIds.length; i++) {
            uint256 stemId = stemIds[i];
            songConfigurations[configId].push(stemId);
            emit SongConfigurationStem(configId, stemId);
        }

        emit NewDefaultSongConfiguration(songId, configId);
    }

    /*
    Notes: theres gotta be permissioning somewhere. Maybe look up some permissioning libaries
    Pop into the public assembly forum to learn from them
    */
    function deleteStem(uint256 stemId) public {
        emit StemDeleted(stemId);
    }

    function updateStem(
        uint256 songId, 
        uint256 stemId, 
        string memory uri, 
        uint16 duration, 
        bool isLoop) public {
        if (stemToSong[stemId] != songId) {
            revert();
        }


        stems[stemId].uri = uri;
        stems[stemId].duration = duration;
        stems[stemId].isLoop = isLoop;

        emit NewStem(songId, stemId, uri, duration, isLoop);
    }


    function getSong(uint256 songId) public view returns (Song memory) {
        return songs[songId];
    }

    /*
    * Returns configId
    */
    function getDefaultSongConfiguration(uint256 songId) public view returns (uint256 ) {
        return defaultSongConfigurations[songId];
    }

    /*
    * Returns list of stemIds in a song configuration
    */
    function getSongConfiguration(uint256 configId) public view returns (uint256 [] memory) {
        return songConfigurations[configId];
    }

    /*
    * Returns stem
    */
    function getStem(uint256 stemId) public view returns (Stem memory) {
        return stems[stemId];
    }

    function getStemTypes(uint256 stemId) public view returns (StemType[] memory) {
        return stemToTypes[stemId];
    }

}