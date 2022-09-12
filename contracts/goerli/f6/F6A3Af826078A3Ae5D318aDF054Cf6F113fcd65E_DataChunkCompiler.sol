// SPDX-License-Identifier: Unlicense
// by dom; use however you like

pragma solidity ^0.8.1;

interface IDataChunk {
    function data() external view returns (string memory);
}

interface IDataChunkCompiler {
    function HTML_HEAD() external view returns (string memory);
    function BEGIN_SCRIPT_DATA() external view returns (string memory);
    function END_SCRIPT_DATA() external view returns (string memory);
    function BEGIN_SCRIPT_DATA_COMPRESSED() external view returns (string memory);
    function END_SCRIPT_DATA_COMPRESSED() external view returns (string memory);
    function SCRIPT_VAR(string memory name, string memory value, bool omitQuotes) external pure returns (string memory);

    function compile2(address chunk1, address chunk2) external view returns (string memory);
    function compile3(address chunk1, address chunk2, address chunk3) external returns (string memory);
    function compile4(address chunk1, address chunk2, address chunk3, address chunk4)
        external view returns (string memory);
    function compile5(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5)
        external view returns (string memory);
    function compile6(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6)
        external view returns (string memory);
    function compile7(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6, address chunk7)
        external view returns (string memory);
    function compile8(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6, address chunk7, address chunk8)
        external view returns (string memory);
    function compile9(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6, address chunk7, address chunk8, address chunk9)
        external view returns (string memory);
}

contract DataChunkCompiler {
    address public immutable owner;

    // via https://gist.github.com/enepomnyaschih/72c423f727d395eeaa09697058238727 (MIT License)
    string public constant base64Utils = 'data:text/javascript;base64,Y29uc3QgYmFzZTY0YWJjID0gWwogICJBIiwgIkIiLCAiQyIsICJEIiwgIkUiLCAiRiIsICJHIiwgIkgiLCAiSSIsICJKIiwgIksiLCAiTCIsICJNIiwKICAiTiIsICJPIiwgIlAiLCAiUSIsICJSIiwgIlMiLCAiVCIsICJVIiwgIlYiLCAiVyIsICJYIiwgIlkiLCAiWiIsCiAgImEiLCAiYiIsICJjIiwgImQiLCAiZSIsICJmIiwgImciLCAiaCIsICJpIiwgImoiLCAiayIsICJsIiwgIm0iLAogICJuIiwgIm8iLCAicCIsICJxIiwgInIiLCAicyIsICJ0IiwgInUiLCAidiIsICJ3IiwgIngiLCAieSIsICJ6IiwKICAiMCIsICIxIiwgIjIiLCAiMyIsICI0IiwgIjUiLCAiNiIsICI3IiwgIjgiLCAiOSIsICIrIiwgIi8iCl07Cgpjb25zdCBiYXNlNjRjb2RlcyA9IFsKICAyNTUsIDI1NSwgMjU1LCAyNTUsIDI1NSwgMjU1LCAyNTUsIDI1NSwgMjU1LCAyNTUsIDI1NSwgMjU1LCAyNTUsIDI1NSwgMjU1LCAyNTUsCiAgMjU1LCAyNTUsIDI1NSwgMjU1LCAyNTUsIDI1NSwgMjU1LCAyNTUsIDI1NSwgMjU1LCAyNTUsIDI1NSwgMjU1LCAyNTUsIDI1NSwgMjU1LAogIDI1NSwgMjU1LCAyNTUsIDI1NSwgMjU1LCAyNTUsIDI1NSwgMjU1LCAyNTUsIDI1NSwgMjU1LCA2MiwgMjU1LCAyNTUsIDI1NSwgNjMsCiAgNTIsIDUzLCA1NCwgNTUsIDU2LCA1NywgNTgsIDU5LCA2MCwgNjEsIDI1NSwgMjU1LCAyNTUsIDAsIDI1NSwgMjU1LAogIDI1NSwgMCwgMSwgMiwgMywgNCwgNSwgNiwgNywgOCwgOSwgMTAsIDExLCAxMiwgMTMsIDE0LAogIDE1LCAxNiwgMTcsIDE4LCAxOSwgMjAsIDIxLCAyMiwgMjMsIDI0LCAyNSwgMjU1LCAyNTUsIDI1NSwgMjU1LCAyNTUsCiAgMjU1LCAyNiwgMjcsIDI4LCAyOSwgMzAsIDMxLCAzMiwgMzMsIDM0LCAzNSwgMzYsIDM3LCAzOCwgMzksIDQwLAogIDQxLCA0MiwgNDMsIDQ0LCA0NSwgNDYsIDQ3LCA0OCwgNDksIDUwLCA1MQpdOwoKZnVuY3Rpb24gZ2V0QmFzZTY0Q29kZShjaGFyQ29kZSkgewogIGlmIChjaGFyQ29kZSA+PSBiYXNlNjRjb2Rlcy5sZW5ndGgpIHsKICAgIHRocm93IG5ldyBFcnJvcigiVW5hYmxlIHRvIHBhcnNlIGJhc2U2NCBzdHJpbmcuIik7CiAgfQogIGNvbnN0IGNvZGUgPSBiYXNlNjRjb2Rlc1tjaGFyQ29kZV07CiAgaWYgKGNvZGUgPT09IDI1NSkgewogICAgdGhyb3cgbmV3IEVycm9yKCJVbmFibGUgdG8gcGFyc2UgYmFzZTY0IHN0cmluZy4iKTsKICB9CiAgcmV0dXJuIGNvZGU7Cn0KCmZ1bmN0aW9uIGJ5dGVzVG9CYXNlNjQoYnl0ZXMpIHsKICBsZXQgcmVzdWx0ID0gJycsIGksIGwgPSBieXRlcy5sZW5ndGg7CiAgZm9yIChpID0gMjsgaSA8IGw7IGkgKz0gMykgewogICAgcmVzdWx0ICs9IGJhc2U2NGFiY1tieXRlc1tpIC0gMl0gPj4gMl07CiAgICByZXN1bHQgKz0gYmFzZTY0YWJjWygoYnl0ZXNbaSAtIDJdICYgMHgwMykgPDwgNCkgfCAoYnl0ZXNbaSAtIDFdID4+IDQpXTsKICAgIHJlc3VsdCArPSBiYXNlNjRhYmNbKChieXRlc1tpIC0gMV0gJiAweDBGKSA8PCAyKSB8IChieXRlc1tpXSA+PiA2KV07CiAgICByZXN1bHQgKz0gYmFzZTY0YWJjW2J5dGVzW2ldICYgMHgzRl07CiAgfQogIGlmIChpID09PSBsICsgMSkgeyAvLyAxIG9jdGV0IHlldCB0byB3cml0ZQogICAgcmVzdWx0ICs9IGJhc2U2NGFiY1tieXRlc1tpIC0gMl0gPj4gMl07CiAgICByZXN1bHQgKz0gYmFzZTY0YWJjWyhieXRlc1tpIC0gMl0gJiAweDAzKSA8PCA0XTsKICAgIHJlc3VsdCArPSAiPT0iOwogIH0KICBpZiAoaSA9PT0gbCkgeyAvLyAyIG9jdGV0cyB5ZXQgdG8gd3JpdGUKICAgIHJlc3VsdCArPSBiYXNlNjRhYmNbYnl0ZXNbaSAtIDJdID4+IDJdOwogICAgcmVzdWx0ICs9IGJhc2U2NGFiY1soKGJ5dGVzW2kgLSAyXSAmIDB4MDMpIDw8IDQpIHwgKGJ5dGVzW2kgLSAxXSA+PiA0KV07CiAgICByZXN1bHQgKz0gYmFzZTY0YWJjWyhieXRlc1tpIC0gMV0gJiAweDBGKSA8PCAyXTsKICAgIHJlc3VsdCArPSAiPSI7CiAgfQogIHJldHVybiByZXN1bHQ7Cn0KCmZ1bmN0aW9uIGJhc2U2NFRvQnl0ZXMoc3RyKSB7CiAgaWYgKHN0ci5sZW5ndGggJSA0ICE9PSAwKSB7CiAgICB0aHJvdyBuZXcgRXJyb3IoIlVuYWJsZSB0byBwYXJzZSBiYXNlNjQgc3RyaW5nLiIpOwogIH0KICBjb25zdCBpbmRleCA9IHN0ci5pbmRleE9mKCI9Iik7CiAgaWYgKGluZGV4ICE9PSAtMSAmJiBpbmRleCA8IHN0ci5sZW5ndGggLSAyKSB7CiAgICB0aHJvdyBuZXcgRXJyb3IoIlVuYWJsZSB0byBwYXJzZSBiYXNlNjQgc3RyaW5nLiIpOwogIH0KICBsZXQgbWlzc2luZ09jdGV0cyA9IHN0ci5lbmRzV2l0aCgiPT0iKSA/IDIgOiBzdHIuZW5kc1dpdGgoIj0iKSA/IDEgOiAwLAogICAgbiA9IHN0ci5sZW5ndGgsCiAgICByZXN1bHQgPSBuZXcgVWludDhBcnJheSgzICogKG4gLyA0KSksCiAgICBidWZmZXI7CiAgZm9yIChsZXQgaSA9IDAsIGogPSAwOyBpIDwgbjsgaSArPSA0LCBqICs9IDMpIHsKICAgIGJ1ZmZlciA9CiAgICAgIGdldEJhc2U2NENvZGUoc3RyLmNoYXJDb2RlQXQoaSkpIDw8IDE4IHwKICAgICAgZ2V0QmFzZTY0Q29kZShzdHIuY2hhckNvZGVBdChpICsgMSkpIDw8IDEyIHwKICAgICAgZ2V0QmFzZTY0Q29kZShzdHIuY2hhckNvZGVBdChpICsgMikpIDw8IDYgfAogICAgICBnZXRCYXNlNjRDb2RlKHN0ci5jaGFyQ29kZUF0KGkgKyAzKSk7CiAgICByZXN1bHRbal0gPSBidWZmZXIgPj4gMTY7CiAgICByZXN1bHRbaiArIDFdID0gKGJ1ZmZlciA+PiA4KSAmIDB4RkY7CiAgICByZXN1bHRbaiArIDJdID0gYnVmZmVyICYgMHhGRjsKICB9CiAgcmV0dXJuIHJlc3VsdC5zdWJhcnJheSgwLCByZXN1bHQubGVuZ3RoIC0gbWlzc2luZ09jdGV0cyk7Cn0=';

    string public constant BEGIN_SCRIPT_DATA = "%3Cscript%20src%3D%27"; // <script src='
    string public constant END_SCRIPT_DATA = "%27%3E%3C%2Fscript%3E"; // '></script>
    string public constant BEGIN_SCRIPT_DATA_COMPRESSED = "%3Cscript%3Evar%2520data%20%3D%20base64ToBytes%28%27"; // <script>var%20data = base64ToBytes('
    string public constant END_SCRIPT_DATA_COMPRESSED = "%27%29%3B%20var%2520unzipped%20%3D%20fflate.gunzipSync%28data%29%3B%20var%2520text%20%3D%20fflate.strFromU8%28unzipped%29%3B%20var%2520b64%20%3D%20btoa%28text%29%3B%20var%2520script%20%3D%20document.createElement%28%27script%27%29%3B%20script.setAttribute%28%27src%27%2C%27data%3Atext%2Fjavascript%3Bbase64%2C%27%20%2B%20b64%29%3B%20document.head.appendChild%28script%29%3B%3C%2Fscript%3E";
    //string public constant END_SCRIPT_DATA_COMPRESSED = "'); var%20unzipped = fflate.gunzipSync(data); var%20text = fflate.strFromU8(unzipped); var%20b64 = btoa(text); var%20script = document.createElement('script'); script.setAttribute('src','data:text/javascript;base64,' + b64); document.head.appendChild(script);</script>";


    address[2] private fflateAddresses;

    constructor() {
        owner = msg.sender;
    }

    function setFFlateAddress(address chunk1, address chunk2) public {
        require(msg.sender == owner);
        fflateAddresses[0] = chunk1;
        fflateAddresses[1] = chunk2;
    }

    function fflate() public view returns (string memory) {
        return compile2(fflateAddresses[0], fflateAddresses[1]);
    }

    function HTML_HEAD() public view returns (string memory) {
        return string(abi.encodePacked(
            'data%3Atext%2Fhtml%2C', // data:text/html,

            BEGIN_SCRIPT_DATA,
                base64Utils,
            END_SCRIPT_DATA,

            BEGIN_SCRIPT_DATA,
                fflate(),
            END_SCRIPT_DATA
        ));
    }

    function SCRIPT_VAR(string memory name, string memory value, bool omitQuotes) public pure returns (string memory) {
        if (omitQuotes) {
            return string(abi.encodePacked(
                'var%20', name, '%3D', value, '%3B' // space, equal, semicolon
            ));
        }
        return string(abi.encodePacked(
            'var%20%22', name, '%3D"', value, '%22%3B' // space, quote, equal, quote, semicolon
        ));
    }

    function compile2(address chunk1, address chunk2) public view returns (string memory) {
        IDataChunk data1 = IDataChunk(chunk1);
        IDataChunk data2 = IDataChunk(chunk2);
        return string(abi.encodePacked(data1.data(), data2.data()));
    }

    function compile3(address chunk1, address chunk2, address chunk3) public view returns (string memory) {

        IDataChunk data1 = IDataChunk(chunk1);
        IDataChunk data2 = IDataChunk(chunk2);
        IDataChunk data3 = IDataChunk(chunk3);
        return string(abi.encodePacked(
            data1.data(), 
            data2.data(),
            data3.data()
        ));
    }

    function compile4(address chunk1, address chunk2, address chunk3, address chunk4)
        public view returns (string memory) {

        IDataChunk data1 = IDataChunk(chunk1);
        IDataChunk data2 = IDataChunk(chunk2);
        IDataChunk data3 = IDataChunk(chunk3);
        IDataChunk data4 = IDataChunk(chunk4);
        return string(abi.encodePacked(
            data1.data(), 
            data2.data(),
            data3.data(),
            data4.data()
        ));
    }

    function compile5(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5)
        public view returns (string memory) {

        IDataChunk data1 = IDataChunk(chunk1);
        IDataChunk data2 = IDataChunk(chunk2);
        IDataChunk data3 = IDataChunk(chunk3);
        IDataChunk data4 = IDataChunk(chunk4);
        IDataChunk data5 = IDataChunk(chunk5);
        return string(abi.encodePacked(
            data1.data(), 
            data2.data(),
            data3.data(),
            data4.data(),
            data5.data()
        ));
    }

    function compile6(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6)
        public view returns (string memory) {

        IDataChunk data1 = IDataChunk(chunk1);
        IDataChunk data2 = IDataChunk(chunk2);
        IDataChunk data3 = IDataChunk(chunk3);
        IDataChunk data4 = IDataChunk(chunk4);
        IDataChunk data5 = IDataChunk(chunk5);
        IDataChunk data6 = IDataChunk(chunk6);
        return string(abi.encodePacked(
            data1.data(), 
            data2.data(),
            data3.data(),
            data4.data(),
            data5.data(),
            data6.data()
        ));
    }

    function compile7(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6, address chunk7)
        public view returns (string memory) {

        IDataChunk data1 = IDataChunk(chunk1);
        IDataChunk data2 = IDataChunk(chunk2);
        IDataChunk data3 = IDataChunk(chunk3);
        IDataChunk data4 = IDataChunk(chunk4);
        IDataChunk data5 = IDataChunk(chunk5);
        IDataChunk data6 = IDataChunk(chunk6);
        IDataChunk data7 = IDataChunk(chunk7);
        return string(abi.encodePacked(
            data1.data(), 
            data2.data(),
            data3.data(),
            data4.data(),
            data5.data(),
            data6.data(),
            data7.data()
        ));
    }

    function compile8(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6, address chunk7, address chunk8)
        public view returns (string memory) {

        IDataChunk data1 = IDataChunk(chunk1);
        IDataChunk data2 = IDataChunk(chunk2);
        IDataChunk data3 = IDataChunk(chunk3);
        IDataChunk data4 = IDataChunk(chunk4);
        IDataChunk data5 = IDataChunk(chunk5);
        IDataChunk data6 = IDataChunk(chunk6);
        IDataChunk data7 = IDataChunk(chunk7);
        IDataChunk data8 = IDataChunk(chunk8);
        return string(abi.encodePacked(
            data1.data(), 
            data2.data(),
            data3.data(),
            data4.data(),
            data5.data(),
            data6.data(),
            data7.data(),
            data8.data()
        ));
    }

    function compile9(address chunk1, address chunk2, address chunk3, address chunk4,
        address chunk5, address chunk6, address chunk7, address chunk8, address chunk9)
        public view returns (string memory) {

        IDataChunk data1 = IDataChunk(chunk1);
        IDataChunk data2 = IDataChunk(chunk2);
        IDataChunk data3 = IDataChunk(chunk3);
        IDataChunk data4 = IDataChunk(chunk4);
        IDataChunk data5 = IDataChunk(chunk5);
        IDataChunk data6 = IDataChunk(chunk6);
        IDataChunk data7 = IDataChunk(chunk7);
        IDataChunk data8 = IDataChunk(chunk8);
        IDataChunk data9 = IDataChunk(chunk9);
        return string(abi.encodePacked(
            data1.data(), 
            data2.data(),
            data3.data(),
            data4.data(),
            data5.data(),
            data6.data(),
            data7.data(),
            data8.data(),
            data9.data()
        ));
    }
}