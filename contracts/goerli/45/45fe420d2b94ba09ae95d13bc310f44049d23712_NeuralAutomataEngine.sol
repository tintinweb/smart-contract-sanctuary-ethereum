// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

struct Content {
    bytes32 checksum;
    address pointer;
}

struct File {
    uint256 size; // content length in bytes, max 24k
    Content[] contents;
}

function read(File memory file) view returns (string memory contents) {
    Content[] memory chunks = file.contents;

    // Adapted from https://gist.github.com/xtremetom/20411eb126aaf35f98c8a8ffa00123cd
    assembly {
        let len := mload(chunks)
        let totalSize := 0x20
        contents := mload(0x40)
        let size
        let chunk
        let pointer

        // loop through all pointer addresses
        // - get content
        // - get address
        // - get data size
        // - get code and add to contents
        // - update total size

        for { let i := 0 } lt(i, len) { i := add(i, 1) } {
            chunk := mload(add(chunks, add(0x20, mul(i, 0x20))))
            pointer := mload(add(chunk, 0x20))

            size := sub(extcodesize(pointer), 1)
            extcodecopy(pointer, add(contents, totalSize), 1, size)
            totalSize := add(totalSize, size)
        }

        // update contents size
        mstore(contents, sub(totalSize, 0x20))
        // store contents
        mstore(0x40, add(contents, and(add(totalSize, 0x1f), not(0x1f))))
    }
}

using {
    read
} for File global;

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IContentStore {
    event NewChecksum(bytes32 indexed checksum, uint256 contentSize);

    error ChecksumExists(bytes32 checksum);
    error ChecksumNotFound(bytes32 checksum);

    function pointers(bytes32 checksum) external view returns (address pointer);

    function checksumExists(bytes32 checksum) external view returns (bool);

    function contentLength(bytes32 checksum)
        external
        view
        returns (uint256 size);

    function addPointer(address pointer) external returns (bytes32 checksum);

    function addContent(bytes memory content)
        external
        returns (bytes32 checksum, address pointer);

    function getPointer(bytes32 checksum)
        external
        view
        returns (address pointer);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {File} from "./File.sol";
import {IContentStore} from "./IContentStore.sol";

interface IFileStore {
    event FileCreated(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        string filename,
        uint256 size,
        bytes metadata
    );
    event FileDeleted(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        string filename
    );

    error FileNotFound(string filename);
    error FilenameExists(string filename);
    error EmptyFile();

    function contentStore() external view returns (IContentStore);

    function files(string memory filename)
        external
        view
        returns (bytes32 checksum);

    function fileExists(string memory filename) external view returns (bool);

    function getChecksum(string memory filename)
        external
        view
        returns (bytes32 checksum);

    function getFile(string memory filename)
        external
        view
        returns (File memory file);

    function createFile(string memory filename, bytes32[] memory checksums)
        external
        returns (File memory file);

    function createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) external returns (File memory file);

    function deleteFile(string memory filename) external;
}

/* SPDX-License-Identifier: MIT
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWMMMNNWWWWWWX00KNWWWWNNWWNWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMWWMWWMMWWNX00Okkkdlloddoolc,,loooollooooxkkOKXNNNWWWWWMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMWWWNWMWXKXK00kddl:ll:;lo:cdxxood:.,c:l:'.',,..''';:coxO0XXNNWWWMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMNXXK0O00dcccccldOkxkOxokkooxxdloo'.c:;:;',;;'.'..'.',,,;cok0KXNNWWWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMWWNKxl:;;;c;,cdkkxkkdllc;:l;''''',..........','.'..........,:lx0KXXNNWWMMMMMMMMMMM
MMMMMMMMMWNNNMMWWWXKkdc;;:;::;,,',:;,'''''.....   ...         ..................,:ok0KXNNWWMMMMMMMMM
MMMMMMMMWWX00KKXXOdllodkOdclc::,..      .....    ..............      ........  ...';lx0KXXNNWWMMMMMM
MMMMMMMMWNXXOoooccokOOOO0kddl:;'.   ....   ...'',::;:loc,;::;,....    .''.......  ..',:dOKKXNNWMMMMM
MMMMMMMMMWX0Oxc;::;:clccc:;,.......':c:. ..:oooox0KOOOo,..,:ll:,'...  .:ooc;'''..    ...:dO0KXNWMMMM
MMMMMMMWNNNK0kdl:,.............,;coOKOl'..'cxkO0XNNKd;.    .;ll:,......;dOOkdl:,''..    .,cxkOKXWMMM
MMWWMMMWNX0xkxl;,......    .'cdkKXNNN0l'.,:ldxddxxo:.       ;odl;,....';dOKKK0d:;;,,'......,lxk0XWMM
MMWNXXNWWX0kl;;,...      ..ckKXWWWWMWXx:cdkkxxxxdol:,..    'lxdc;;'''.'ckKXXXK0xlc;,,;;,'..',cxOXWMM
MMMMWXK0KX0xc;;::;.......;oOXNWWMMMMMWXkodxOKXKOxddddo;'';coxoc:;,'''';dKNNNXK0kdl:;:cclolclccxKNWMM
MMMMWWWNX0kdc;;;,,';lxkl,,lOXWWMMMMMMMMXxoloddddddxxdxxdodddxl;;:;,'.,o0NNNNXK0koc::cclkK0kkddOXNWMM
MMMWNXXXNXKKKKKkxxddxdddo:;l0NMMMMMMMMMMXkl:ccooc:::loooccc:l:,;,,..,o0NWNNNK0kdl;,;;coxxdc;:dKNNWMM
MMMMMMMMMMMMWWWNNXKOdoddxddoxKNWMMMMMMMMMW0o:;::;;:c::cc:;;;;,'...':xKXNXXKKOkxl;'.....'''':xXWWWWWM
MMMMMMMMMMMMMMMMMMN0xodddxkkddk0NWMMMMMMMMMNkl;',;;;,,;'''.......,lkKKXK0Oxoc;,.......;ldkOKNWWWWWMM
MMMMMMMMMMMMMMMMMWNXXK0OkddxkkkkkkOKNWMMMMMMMNKkolc:,''.....'';ldk00Oxdoc;'...,;:cloodOKKXXNNWWWWMMM
MMMMMMMMMMMMMMMMMWMMMWNX0kkxxdloc:cloxxkOKXXXNNNXKK0kddoolllooddoccc:,',,;;:clxkO000KXXXXNNNNNWWMMMM
MMMMMMMMMMMMMMMMMMMMMWWNXNN0oooddllllolccllcloodddoolllccccccloxl,,:c:;::ldxkO0KXXXXXXXXXNNNWWMMMMMM
MMMMMMMMMMMMMMMMMMMMMMWNWMN0OOO00kxxxocoxdoccldxlcloocodllc;;:clc,;:cllddkO0000KKKKKKXXNNWWWMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWNNKKXNWNXKOxOKOdodxxxdc:;:c:cl:;:;:::cccldkOOOOO00000KK0KKXXNWWMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWNNNMMMWWNXKKXNKXXK00Oxlc:lddlllllldxkOkO00000OOO000000KKXXNWWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMWNNMMMMWNNWXXNNNNNKKXK0kxxO0OO0OO0KXXKKK00000K00K000KXXXNNWWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMWNXNWWWWNNNNX0KXNNNNNXXXXXKKKKKKKKXKKKKKXXNNNWWWMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMMWWWWWNNWWNNNNXXXXXXXXXXXXKXXXNNWWWWWWMMMMMMMMMMMMMMMMMMMM
*/

pragma solidity 0.8.15;

import {INeuralAutomataEngine, NCAParams} from "./interfaces/INeuralAutomataEngine.sol";
import {IFileStore} from "../lib/ethfs/packages/contracts/src/IFileStore.sol";
import {Base64} from "./utils/Base64.sol";

contract NeuralAutomataEngine is INeuralAutomataEngine {

    IFileStore fileStore;

    string public baseScript;

    constructor(address _fileStore, string memory _baseScript){
        fileStore = IFileStore(_fileStore);
        baseScript = _baseScript;
    }

    function parameters(NCAParams memory _params) public pure returns(string memory) {
        return string.concat(
            "let seed = ",
            _params.seed,
            "; let bg = ",
            _params.bg,
            "; let fg1 = ",
            _params.fg1,
            "; let fg2 = ",
            _params.fg2,
            "; let matrix = ",
            _params.matrix,
            ";function activation(x){",
            _params.activation,
            "} function rand() {",
            _params.rand,
            "}"
        );
    }

    function p5() public view returns(string memory) {
        return string.concat(
            "<script type=\"text/javascript+gzip\" src=\"data:text/javascript;base64,",
            fileStore.getFile("p5-v1.5.0.min.js.gz").read(),
            "\"></script>",
            "<script src=\"data:text/javascript;base64,",
            fileStore.getFile("gunzipScripts-0.0.1.js").read(),
            "\"></script>"
        );
    }

    function script(NCAParams memory _params) public view returns(string memory) {
        return string.concat(
            "<script src=\"data:text/javascript;base64,",
            Base64.encode(
                abi.encodePacked(
                    string.concat(
                        parameters(_params),
                        baseScript,
                        _params.mods
                    )
                )
            ),
            "\"></script>"
        );
    }

    function page(NCAParams memory _params) public view returns(string memory) {
        return string.concat(
            "data:text/html;base64,",
            Base64.encode(
                abi.encodePacked(
                    string.concat(
                        "<!DOCTYPE html><html style=\"height: 100%;\"><body style=\"margin: 0;display: flex;justify-content: center;align-items: center;height: 100%;\">",
                        p5(),
                        script(_params),
                        "</body></html>"
                    )
                )
            )
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

struct NCAParams {
    string seed;
    string bg;
    string fg1;
    string fg2;
    string matrix;
    string activation;
    string rand;
    string mods;
}

interface INeuralAutomataEngine {
    function baseScript() external view returns(string memory);

    function parameters(NCAParams memory _params) external pure returns(string memory);

    function p5() external view returns(string memory);

    function script(NCAParams memory _params) external view returns(string memory);

    function page(NCAParams memory _params) external view returns(string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

library Base64 {
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) public pure returns (string memory) {
      if (data.length == 0) return "";

      string memory table = _TABLE;
      string memory result = new string(4 * ((data.length + 2) / 3));

      assembly {
          let tablePtr := add(table, 1)
          let resultPtr := add(result, 32)

          for {
              let dataPtr := data
              let endPtr := add(data, mload(data))
          } lt(dataPtr, endPtr) {

          } {
              dataPtr := add(dataPtr, 3)
              let input := mload(dataPtr)
              mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
              resultPtr := add(resultPtr, 1) 
              mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
              resultPtr := add(resultPtr, 1) 
              mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
              resultPtr := add(resultPtr, 1) 
              mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
              resultPtr := add(resultPtr, 1) 
          }
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