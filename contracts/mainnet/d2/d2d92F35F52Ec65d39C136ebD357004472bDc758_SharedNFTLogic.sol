// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/*
 ______   _______  _______  _______  _       _________
(  __  \ (  ____ \(  ____ \(  ____ \( (    /|\__   __/
| (  \  )| (    \/| (    \/| (    \/|  \  ( |   ) (
| |   ) || (__    | |      | (__    |   \ | |   | |
| |   | ||  __)   | |      |  __)   | (\ \) |   | |
| |   ) || (      | |      | (      | | \   |   | |
| (__/  )| (____/\| (____/\| (____/\| )  \  |   | |
(______/ (_______/(_______/(_______/|/    )_)   )_(

*/

/// ============ Imports ============
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import "../interfaces/IOnChainMetadata.sol";

/// Shared NFT logic for rendering metadata associated with editions
/// @dev Can safely be used for generic base64Encode and numberToString functions
contract SharedNFTLogic is IOnChainMetadata {
  /// @param unencoded bytes to base64-encode
  function base64Encode(bytes memory unencoded)
    public
    pure
    returns (string memory)
  {
    return Base64.encode(unencoded);
  }

  /// Proxy to openzeppelin's toString function
  /// @param value number to return as a string
  function numberToString(uint256 value) public pure returns (string memory) {
    return Strings.toString(value);
  }

  /// Generate edition metadata from storage information as base64-json blob
  /// Combines the media data and metadata
  /// @param name the token name
  /// @param tokenOfEdition Token ID for specific token
  /// @param songMetadata song metadata
  /// @param projectMetadata project metadata
  /// @param credits The credits of the track
  /// @param tags The tags of the track
  function createMetadataEdition(
    string memory name,
    uint256 tokenOfEdition,
    SongMetadata memory songMetadata,
    ProjectMetadata memory projectMetadata,
    Credit[] memory credits,
    string[] memory tags
  ) external pure returns (string memory) {
    bytes memory json = createMetadataJSON(
      name,
      tokenOfEdition,
      songMetadata,
      projectMetadata,
      credits,
      tags
    );
    return encodeMetadataJSON(json);
  }

  /// Function to create the metadata json string for the nft edition
  /// @param name Name of NFT in metadata
  /// @param tokenOfEdition Token ID for specific token
  /// @param songMetadata metadata of the song
  /// @param projectMetadata metadata of the project
  /// @param credits The credits of the track
  /// @param tags The tags of the track
  function createMetadataJSON(
    string memory name,
    uint256 tokenOfEdition,
    SongMetadata memory songMetadata,
    ProjectMetadata memory projectMetadata,
    Credit[] memory credits,
    string[] memory tags
  ) public pure returns (bytes memory) {
    bool isMusicNft = bytes(
      songMetadata.song.audio.songDetails.audioQuantitative.audioMimeType
    ).length > 0;
    if (isMusicNft) {
      return
        createMusicMetadataJSON(
          songMetadata.songPublishingData.title,
          tokenOfEdition,
          songMetadata,
          projectMetadata,
          credits,
          tags
        );
    }
    return
      createBaseMetadataEdition(
        name,
        songMetadata.songPublishingData.description,
        songMetadata.song.artwork.artworkUri,
        songMetadata.song.audio.losslessAudio,
        tokenOfEdition
      );
  }

  /// Function to create the metadata json string for the nft edition
  /// @param name Name of NFT in metadata
  /// @param tokenOfEdition Token ID for specific token
  /// @param songMetadata metadata of the song
  /// @param projectMetadata metadata of the project
  /// @param credits The credits of the track
  /// @param tags The tags of the track
  function createMusicMetadataJSON(
    string memory name,
    uint256 tokenOfEdition,
    SongMetadata memory songMetadata,
    ProjectMetadata memory projectMetadata,
    Credit[] memory credits,
    string[] memory tags
  ) public pure returns (bytes memory) {
    bytes memory songMetadataFormatted = _formatSongMetadata(songMetadata);
    return
      abi.encodePacked(
        '{"version": "0.1", "name": "',
        name,
        " ",
        numberToString(tokenOfEdition),
        '",',
        songMetadataFormatted,
        ", ",
        _formatProjectMetadata(projectMetadata),
        ", ",
        _formatExtras(
          tokenOfEdition,
          songMetadata,
          projectMetadata,
          tags,
          credits
        ),
        "}"
      );
  }

  /// Generate edition metadata from storage information as base64-json blob
  /// Combines the media data and metadata
  /// @param name Name of NFT in metadata
  /// @param description Description of NFT in metadata
  /// @param imageUrl URL of image to render for edition
  /// @param animationUrl URL of animation to render for edition
  /// @param tokenOfEdition Token ID for specific token
  function createBaseMetadataEdition(
    string memory name,
    string memory description,
    string memory imageUrl,
    string memory animationUrl,
    uint256 tokenOfEdition
  ) public pure returns (bytes memory) {
    return
      abi.encodePacked(
        '{"name": "',
        name,
        " ",
        numberToString(tokenOfEdition),
        '", "',
        'description": "',
        description,
        '", "',
        tokenMediaData(imageUrl, animationUrl, tokenOfEdition),
        'properties": {"number": ',
        numberToString(tokenOfEdition),
        ', "name": "',
        name,
        '"}}'
      );
  }

  /// Generates edition metadata from storage information as base64-json blob
  /// Combines the media data and metadata
  /// @param imageUrl URL of image to render for edition
  /// @param animationUrl URL of animation to render for edition
  function tokenMediaData(
    string memory imageUrl,
    string memory animationUrl,
    uint256 tokenOfEdition
  ) public pure returns (string memory) {
    bool hasImage = bytes(imageUrl).length > 0;
    bool hasAnimation = bytes(animationUrl).length > 0;
    if (hasImage && hasAnimation) {
      return
        string(
          abi.encodePacked(
            'image": "',
            imageUrl,
            "?id=",
            numberToString(tokenOfEdition),
            '", "animation_url": "',
            animationUrl,
            "?id=",
            numberToString(tokenOfEdition),
            '", "'
          )
        );
    }
    if (hasImage) {
      return
        string(
          abi.encodePacked(
            'image": "',
            imageUrl,
            "?id=",
            numberToString(tokenOfEdition),
            '", "'
          )
        );
    }
    if (hasAnimation) {
      return
        string(
          abi.encodePacked(
            'animation_url": "',
            animationUrl,
            "?id=",
            numberToString(tokenOfEdition),
            '", "'
          )
        );
    }

    return "";
  }

  /// Encodes the argument json bytes into base64-data uri format
  /// @param json Raw json to base64 and turn into a data-uri
  function encodeMetadataJSON(bytes memory json)
    public
    pure
    returns (string memory)
  {
    return
      string(
        abi.encodePacked("data:application/json;base64,", base64Encode(json))
      );
  }

  function _formatSongMetadata(SongMetadata memory songMetadata)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        _formatAudio(songMetadata.song.audio),
        ",",
        _formatPublishingData(songMetadata.songPublishingData),
        ",",
        _formatArtwork("artwork", songMetadata.song.artwork),
        ",",
        _formatArtwork("visualizer", songMetadata.song.visualizer),
        ",",
        _formatLyrics(songMetadata.song.audio.lyrics),
        ',"image":"',
        songMetadata.song.artwork.artworkUri,
        '"'
      );
  }

  function _formatProjectMetadata(ProjectMetadata memory _metadata)
    internal
    pure
    returns (bytes memory output)
  {
    output = abi.encodePacked(
      '"project": {',
      '"title": "',
      _metadata.publishingData.title,
      '", "description": "',
      _metadata.publishingData.description,
      '", "type": "',
      _metadata.projectType,
      '", "originalReleaseDate": "',
      _metadata.publishingData.releaseDate
    );

    return bytes.concat(output, abi.encodePacked(
      '", "recordLabel": "',
      _metadata.publishingData.recordLabel,
      '", "publisher": "',
      _metadata.publishingData.publisher,
      '", "upc": "',
      _metadata.upc,
      '",',
      _formatArtwork("artwork", _metadata.artwork),
      "}"
    ));
  }

  function _formatAudio(Audio memory audio)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"losslessAudio": "',
        audio.losslessAudio,
        '","animation_url": "',
        audio.losslessAudio,
        '",',
        _formatSongDetails(audio.songDetails)
      );
  }

  function _formatSongDetails(SongDetails memory songDetails)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"artist": "',
        songDetails.artistName,
        '",',
        _formatAudioQuantitative(songDetails.audioQuantitative),
        ",",
        _formatAudioQualitative(songDetails.audioQualitative)
      );
  }

  function _formatAudioQuantitative(
    AudioQuantitative memory audioQuantitativeInfo
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        '"key": "',
        audioQuantitativeInfo.key,
        '", "bpm": ',
        numberToString(audioQuantitativeInfo.bpm),
        ', "duration": ',
        numberToString(audioQuantitativeInfo.duration),
        ', "mimeType": "',
        audioQuantitativeInfo.audioMimeType,
        '", "trackNumber": ',
        numberToString(audioQuantitativeInfo.trackNumber)
      );
  }

  function _formatAudioQualitative(AudioQualitative memory audioQualitative)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"license": "',
        audioQualitative.license,
        '", "external_url": "',
        audioQualitative.externalUrl,
        '", "isrc": "',
        audioQualitative.isrc,
        '", "genre": "',
        audioQualitative.genre,
        '"'
      );
  }

  function _formatPublishingData(PublishingData memory _data)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"title": "',
        _data.title,
        '", "description": "',
        _data.description,
        '", "recordLabel": "',
        _data.recordLabel,
        '", "publisher": "',
        _data.publisher,
        '", "locationCreated": "',
        _data.locationCreated,
        '", "originalReleaseDate": "',
        _data.releaseDate,
        '", "name": "',
        _data.title,
        '"'
      );
  }

  function _formatArtwork(string memory _artworkLabel, Artwork memory _data)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"',
        _artworkLabel,
        '": {',
        '"uri": "',
        _data.artworkUri,
        '", "mimeType": "',
        _data.artworkMimeType,
        '", "nft": "',
        _data.artworkNft,
        '"}'
      );
  }

  function _formatExtras(
    uint256 tokenOfEdition,
    SongMetadata memory songMetadata,
    ProjectMetadata memory projectMetadata,
    string[] memory tags,
    Credit[] memory credits
  ) internal pure returns (bytes memory) {
    return
      abi.encodePacked(
        _formatAttributes(
          "attributes",
          tokenOfEdition,
          songMetadata.song.audio.songDetails,
          projectMetadata,
          songMetadata.songPublishingData
        ),
        ", ",
        _formatAttributes(
          "properties",
          tokenOfEdition,
          songMetadata.song.audio.songDetails,
          projectMetadata,
          songMetadata.songPublishingData
        ),
        ',"tags":',
        _getArrayString(tags),
        ', "credits": ',
        _getCollaboratorString(credits)
      );
  }

  function _formatLyrics(Lyrics memory _data)
    internal
    pure
    returns (bytes memory)
  {
    return
      abi.encodePacked(
        '"lyrics": {',
        '"text": "',
        _data.lyrics,
        '", "nft": "',
        _data.lyricsNft,
        '"}'
      );
  }

  function _formatAttributes(
    string memory _label,
    uint256 _tokenOfEdition,
    SongDetails memory _songDetails,
    ProjectMetadata memory _projectMetadata,
    PublishingData memory _publishingData
  )
    internal
    pure
    returns (bytes memory output)
  {
    AudioQuantitative memory _audioQuantitative = _songDetails
      .audioQuantitative;
    AudioQualitative memory _audioQualitative = _songDetails.audioQualitative;

    output = abi.encodePacked(
      '"',
      _label,
      '": {"number": ',
      numberToString(_tokenOfEdition),
      ', "bpm": ',
      numberToString(_audioQuantitative.bpm),
      ', "key": "',
      _audioQuantitative.key,
      '", "genre": "',
      _audioQualitative.genre
    );

    return bytes.concat(output, abi.encodePacked(
      '", "project": "',
      _projectMetadata.publishingData.title,
      '", "artist": "',
      _songDetails.artistName,
      '", "recordLabel": "',
      _publishingData.recordLabel,
      '", "license": "',
      _audioQualitative.license,
      '"}'
    ));
  }

  function _getArrayString(string[] memory _array)
    internal
    pure
    returns (string memory)
  {
    string memory _string = "[";
    for (uint256 i = 0; i < _array.length; i++) {
      _string = string(abi.encodePacked(_string, _getString(_array[i])));
      if (i < _array.length - 1) {
        _string = string(abi.encodePacked(_string, ","));
      }
    }
    _string = string(abi.encodePacked(_string, "]"));
    return _string;
  }

  function _getString(string memory _string)
    internal
    pure
    returns (string memory)
  {
    return string(abi.encodePacked('"', _string, '"'));
  }

  function _getCollaboratorString(Credit[] memory credits)
    internal
    pure
    returns (string memory)
  {
    string memory _string = "[";
    for (uint256 i = 0; i < credits.length; i++) {
      _string = string(abi.encodePacked(_string, '{"name":'));
      _string = string(abi.encodePacked(_string, _getString(credits[i].name)));
      _string = string(abi.encodePacked(_string, ',"collaboratorType":'));
      _string = string(
        abi.encodePacked(_string, _getString(credits[i].collaboratorType), "}")
      );
      if (i < credits.length - 1) {
        _string = string(abi.encodePacked(_string, ","));
      }
    }
    _string = string(abi.encodePacked(_string, "]"));
    return _string;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOnChainMetadata {
  /// @notice Lyrics updated for this edition
  event SongUpdated(
    address target,
    address sender,
    SongMetadata songMetadata,
    ProjectMetadata projectMetadata,
    string[] tags,
    Credit[] credits
  );

  /// @notice AudioQuantitativeUpdated updated for this edition
  /// @dev admin function indexer feedback
  event AudioQuantitativeUpdated(
    address indexed target,
    address sender,
    string key,
    uint256 bpm,
    uint256 duration,
    string audioMimeType,
    uint256 trackNumber
  );

  /// @notice AudioQualitative updated for this edition
  /// @dev admin function indexer feedback
  event AudioQualitativeUpdated(
    address indexed target,
    address sender,
    string license,
    string externalUrl,
    string isrc,
    string genre
  );

  /// @notice Lyrics updated for this edition
  event LyricsUpdated(
    address target,
    address sender,
    string lyrics,
    string lyricsNft
  );

  /// @notice Artwork updated for this edition
  /// @dev admin function indexer feedback
  event ArtworkUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice Visualizer updated for this edition
  /// @dev admin function indexer feedback
  event VisualizerUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice ProjectMetadata updated for this edition
  /// @dev admin function indexer feedback
  event ProjectArtworkUpdated(
    address indexed target,
    address sender,
    string artworkUri,
    string artworkMimeType,
    string artworkNft
  );

  /// @notice Tags updated for this edition
  /// @dev admin function indexer feedback
  event TagsUpdated(address indexed target, address sender, string[] tags);

  /// @notice Credit updated for this edition
  /// @dev admin function indexer feedback
  event CreditsUpdated(
    address indexed target,
    address sender,
    Credit[] credits
  );

  /// @notice ProjectMetadata updated for this edition
  /// @dev admin function indexer feedback
  event ProjectPublishingDataUpdated(
    address indexed target,
    address sender,
    string title,
    string description,
    string recordLabel,
    string publisher,
    string locationCreated,
    string releaseDate,
    string projectType,
    string upc
  );

  /// @notice PublishingData updated for this edition
  /// @dev admin function indexer feedback
  event PublishingDataUpdated(
    address indexed target,
    address sender,
    string title,
    string description,
    string recordLabel,
    string publisher,
    string locationCreated,
    string releaseDate
  );

  /// @notice losslessAudio updated for this edition
  /// @dev admin function indexer feedback
  event LosslessAudioUpdated(
    address indexed target,
    address sender,
    string losslessAudio
  );

  /// @notice Description updated for this edition
  /// @dev admin function indexer feedback
  event DescriptionUpdated(
    address indexed target,
    address sender,
    string newDescription
  );

  /// @notice Artist updated for this edition
  /// @dev admin function indexer feedback
  event ArtistUpdated(address indexed target, address sender, string newArtist);

  /// @notice Event for updated Media URIs
  event MediaURIsUpdated(
    address indexed target,
    address sender,
    string imageURI,
    string animationURI
  );

  /// @notice Event for a new edition initialized
  /// @dev admin function indexer feedback
  event EditionInitialized(
    address indexed target,
    string description,
    string imageURI,
    string animationURI
  );

  /// @notice Storage for SongMetadata
  struct SongMetadata {
    SongContent song;
    PublishingData songPublishingData;
  }

  /// @notice Storage for SongContent
  struct SongContent {
    Audio audio;
    Artwork artwork;
    Artwork visualizer;
  }

  /// @notice Storage for SongDetails
  struct SongDetails {
    string artistName;
    AudioQuantitative audioQuantitative;
    AudioQualitative audioQualitative;
  }

  /// @notice Storage for Audio
  struct Audio {
    string losslessAudio; // ipfs://{cid} or arweave
    SongDetails songDetails;
    Lyrics lyrics;
  }

  /// @notice Storage for AudioQuantitative
  struct AudioQuantitative {
    string key; // C / A# / etc
    uint256 bpm; // 120 / 60 / 100
    uint256 duration; // 240 / 60 / 120
    string audioMimeType; // audio/wav
    uint256 trackNumber; // 1
  }

  /// @notice Storage for AudioQualitative
  struct AudioQualitative {
    string license; // CC0
    string externalUrl; // Link to your project website
    string isrc; // CC-XXX-YY-NNNNN
    string genre; // Rock / Pop / Metal / Hip-Hop / Electronic / Classical / Jazz / Folk / Reggae / Other
  }

  /// @notice Storage for Artwork
  struct Artwork {
    string artworkUri; // The uri of the artwork (ipfs://<CID>)
    string artworkMimeType; // The mime type of the artwork
    string artworkNft; // The NFT of the artwork (caip19)
  }

  /// @notice Storage for Lyrics
  struct Lyrics {
    string lyrics;
    string lyricsNft;
  }

  /// @notice Storage for PublishingData
  struct PublishingData {
    string title;
    string description;
    string recordLabel; // Sony / Universal / etc
    string publisher; // Sony / Universal / etc
    string locationCreated;
    string releaseDate; // 2020-01-01
  }

  /// @notice Storage for ProjectMetadata
  struct ProjectMetadata {
    PublishingData publishingData;
    Artwork artwork;
    string projectType; // Single / EP / Album
    string upc; // 03600029145
  }

  /// @notice Storage for Credit
  struct Credit {
    string name;
    string collaboratorType;
  }
}