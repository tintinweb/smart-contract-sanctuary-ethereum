pragma solidity ^0.8.7;

contract Art {
    function uint2str(uint _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function st2num(string memory numString) public pure returns (uint) {
        uint val = 0;
        bytes memory stringBytes = bytes(numString);
        for (uint i = 0; i < stringBytes.length; i++) {
            uint exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint jval = uval - uint(0x30);
            val += (uint(jval) * (10**(exp - 1)));
        }
        return val;
    }

    function strIndex2num(string memory numString, uint256 index)
        public
        pure
        returns (uint)
    {
        bytes memory a = new bytes(1);
        a[0] = bytes(numString)[index];
        return st2num(string(a));
    }

    function concatenate(string memory a, string memory b)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, "", b));
    }

    struct ArtData {
        string text;
        string[8] colorArray;
        string[3] speedArray;
        string[3] speedArrayTrajectory;
        string[7] blurArray;
    }

    function makeArt(
        string memory emotion,
        string memory colors,
        string memory eyeDistance,
        uint256 mouthSz,
        uint256 faceSpeed,
        uint256 faceBlur
    ) public view virtual returns (string memory) {
        ArtData memory artDataSlot;
        artDataSlot.colorArray[0] = "#FF0000";
        artDataSlot.colorArray[1] = "#FF7D00";
        artDataSlot.colorArray[2] = "#FFFF00";
        artDataSlot.colorArray[3] = "#00FF00";
        artDataSlot.colorArray[4] = "#00FFFF";
        artDataSlot.colorArray[5] = "#0000FF";
        artDataSlot.colorArray[6] = "#5A00FF";
        artDataSlot.colorArray[7] = "#FF00FF";

        artDataSlot.blurArray[0] = "15";
        artDataSlot.blurArray[1] = "20";
        artDataSlot.blurArray[2] = "25";
        artDataSlot.blurArray[3] = "30";
        artDataSlot.blurArray[4] = "35";
        artDataSlot.blurArray[5] = "40";
        artDataSlot.blurArray[6] = "45";

        artDataSlot.speedArray[0] = "6";
        artDataSlot.speedArray[1] = "4";
        artDataSlot.speedArray[2] = "2";

        artDataSlot.speedArrayTrajectory[
                0
            ] = "M 0 0 l 30 -30 z l 0 30 z l -20 -40 z";
        artDataSlot.speedArrayTrajectory[
                1
            ] = "M 0 0 l 40 30 z l 30 0 z l 20 40 z";
        artDataSlot.speedArrayTrajectory[
                2
            ] = "M 40 40 l -40 -20 z l 30 -30 z l 20 -40 z";

        artDataSlot.text = concatenate(
            '<svg height="500" width="500" xmlns="http://www.w3.org/2000/svg"><defs><filter id="f1" x="-40%" y="-60%" width="800%" height="800%"><feGaussianBlur in="SourceGraphic" stdDeviation="',
            artDataSlot.blurArray[faceBlur]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" /></filter><filter id="f2" x="-100%" y="-150%" width="800%" height="800%"><feGaussianBlur in="SourceGraphic" stdDeviation="15" /></filter><filter id="f3" x="-100%" y="-90%" width="12000%" height="12000%"><feGaussianBlur in="SourceGraphic" stdDeviation="20" /></filter></defs><rect width="100%" height="100%" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 0)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" /><g><circle cx="250" cy="250" r="230" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 1)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" filter="url(#f1)" /><animateMotion dur="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.speedArray[faceSpeed]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            's" repeatCount="indefinite" path="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.speedArrayTrajectory[faceSpeed]
        );
        artDataSlot.text = concatenate(artDataSlot.text, '" /></g>');

        if (keccak256(bytes(emotion)) == keccak256(bytes("happy"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="180" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="180" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="320" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="320" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(160 - mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ",300 C200,380 300,380 "
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(340 + mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ',300" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" stroke-width="40px" stroke-linecap="round" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (
            keccak256(bytes(emotion)) == keccak256(bytes("superHappy"))
        ) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M330.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 309.588 173C324.7 173 340 184.366 340 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M209.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 188.588 173C203.7 173 219 184.366 219 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M209.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 188.588 173C203.7 173 219 184.366 219 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M209.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 188.588 173C203.7 173 219 184.366 219 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(160 - mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ",300 C200,380 300,380 "
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(340 + mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ',300" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" stroke-width="40px" stroke-linecap="round" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("sad"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="180" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="180" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="320" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="320" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(170 - mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ",350 C200,290 300,290 "
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(330 + mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ',350" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" stroke-width="40px" stroke-linecap="round" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("superSad"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M288.025 199c1.185 0 2.359.229 3.454.676a9.038 9.038 0 0 1 2.928 1.924 8.89 8.89 0 0 1 1.957 2.881 8.764 8.764 0 0 1 .687 3.398c0 5.14 1.422 9.288 4.108 11.991a11.446 11.446 0 0 0 3.778 2.512c1.417.579 2.939.871 4.475.859 8.664 0 12.537-7.715 12.537-15.362 0-2.355.951-4.613 2.644-6.279a9.1 9.1 0 0 1 6.382-2.6c2.393 0 4.689.935 6.382 2.6a8.811 8.811 0 0 1 2.643 6.279c0 12.431-5.076 20.132-9.336 24.39a29.602 29.602 0 0 1-9.727 6.485A30.01 30.01 0 0 1 309.412 241C294.3 241 279 229.634 279 207.879c0-1.166.233-2.321.687-3.398a8.888 8.888 0 0 1 1.956-2.881 9.049 9.049 0 0 1 2.928-1.924 9.141 9.141 0 0 1 3.454-.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M288.025 199c1.185 0 2.359.229 3.454.676a9.038 9.038 0 0 1 2.928 1.924 8.89 8.89 0 0 1 1.957 2.881 8.764 8.764 0 0 1 .687 3.398c0 5.14 1.422 9.288 4.108 11.991a11.446 11.446 0 0 0 3.778 2.512c1.417.579 2.939.871 4.475.859 8.664 0 12.537-7.715 12.537-15.362 0-2.355.951-4.613 2.644-6.279a9.1 9.1 0 0 1 6.382-2.6c2.393 0 4.689.935 6.382 2.6a8.811 8.811 0 0 1 2.643 6.279c0 12.431-5.076 20.132-9.336 24.39a29.602 29.602 0 0 1-9.727 6.485A30.01 30.01 0 0 1 309.412 241C294.3 241 279 229.634 279 207.879c0-1.166.233-2.321.687-3.398a8.888 8.888 0 0 1 1.956-2.881 9.049 9.049 0 0 1 2.928-1.924 9.141 9.141 0 0 1 3.454-.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M167.025 199c1.185 0 2.359.229 3.454.676a9.038 9.038 0 0 1 2.928 1.924 8.89 8.89 0 0 1 1.957 2.881 8.764 8.764 0 0 1 .687 3.398c0 5.14 1.422 9.288 4.108 11.991a11.446 11.446 0 0 0 3.778 2.512c1.417.579 2.939.871 4.475.859 8.664 0 12.537-7.715 12.537-15.362 0-2.355.951-4.613 2.644-6.279a9.1 9.1 0 0 1 6.382-2.6c2.393 0 4.689.935 6.382 2.6a8.811 8.811 0 0 1 2.643 6.279c0 12.431-5.076 20.132-9.336 24.39a29.602 29.602 0 0 1-9.727 6.485A30.01 30.01 0 0 1 188.412 241C173.3 241 158 229.634 158 207.879c0-1.166.233-2.321.687-3.398a8.888 8.888 0 0 1 1.956-2.881 9.049 9.049 0 0 1 2.928-1.924 9.141 9.141 0 0 1 3.454-.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M167.025 199c1.185 0 2.359.229 3.454.676a9.038 9.038 0 0 1 2.928 1.924 8.89 8.89 0 0 1 1.957 2.881 8.764 8.764 0 0 1 .687 3.398c0 5.14 1.422 9.288 4.108 11.991a11.446 11.446 0 0 0 3.778 2.512c1.417.579 2.939.871 4.475.859 8.664 0 12.537-7.715 12.537-15.362 0-2.355.951-4.613 2.644-6.279a9.1 9.1 0 0 1 6.382-2.6c2.393 0 4.689.935 6.382 2.6a8.811 8.811 0 0 1 2.643 6.279c0 12.431-5.076 20.132-9.336 24.39a29.602 29.602 0 0 1-9.727 6.485A30.01 30.01 0 0 1 188.412 241C173.3 241 158 229.634 158 207.879c0-1.166.233-2.321.687-3.398a8.888 8.888 0 0 1 1.956-2.881 9.049 9.049 0 0 1 2.928-1.924 9.141 9.141 0 0 1 3.454-.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(170 - mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ",350 C200,290 300,290 "
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(330 + mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ',350" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" stroke-width="40px" stroke-linecap="round" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("angry"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="m273 277 84-56v56h-84Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="m273 277 84-56v56h-84Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="m227 277-84-56v56h84Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="m227 277-84-56v56h84Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(170 - mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ",380 C200,320 300,320 "
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                uint2str(330 + mouthSz)
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ',380" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" stroke-width="40px" stroke-linecap="round" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("fearful"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><ellipse cx="206.5" cy="137" rx="17.5" ry="34" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><ellipse cx="206.5" cy="137" rx="17.5" ry="34" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><ellipse rx="17.5" ry="34" cx="292.5" cy="137" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><ellipse rx="17.5" ry="34" cx="292.5" cy="137" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M252 211c-18.035 0-35.331 16.857-48.083 46.863C191.164 287.869 184 328.565 184 371h136c0-21.011-1.759-41.817-5.176-61.229-3.418-19.412-8.426-37.051-14.741-51.908-6.314-14.857-13.81-26.643-22.061-34.684C269.772 215.138 260.93 211 252 211Z"'
            );
            artDataSlot.text = concatenate(artDataSlot.text, ' fill="');
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("confused"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="196" cy="122" r="50" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="196" cy="122" r="50" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="309" cy="129" r="27" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="309" cy="129" r="27" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><ellipse cx="250" cy="300"  rx="50" ry="91"'
            );
            artDataSlot.text = concatenate(artDataSlot.text, ' fill="');
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (
            keccak256(bytes(emotion)) == keccak256(bytes("celebrated"))
        ) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M330.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 309.588 173C324.7 173 340 184.366 340 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M330.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 309.588 173C324.7 173 340 184.366 340 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M209.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 188.588 173C203.7 173 219 184.366 219 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M209.975 215a9.141 9.141 0 0 1-3.454-.676 9.038 9.038 0 0 1-2.928-1.924 8.89 8.89 0 0 1-1.957-2.881 8.764 8.764 0 0 1-.687-3.398c0-5.14-1.422-9.288-4.108-11.991a11.446 11.446 0 0 0-3.778-2.512 11.594 11.594 0 0 0-4.475-.859c-8.664 0-12.537 7.715-12.537 15.362a8.808 8.808 0 0 1-2.644 6.279 9.1 9.1 0 0 1-6.382 2.6 9.104 9.104 0 0 1-6.382-2.6 8.811 8.811 0 0 1-2.643-6.279c0-12.431 5.076-20.132 9.336-24.39a29.602 29.602 0 0 1 9.727-6.485A30.01 30.01 0 0 1 188.588 173C203.7 173 219 184.366 219 206.121a8.746 8.746 0 0 1-.687 3.398 8.888 8.888 0 0 1-1.956 2.881 9.049 9.049 0 0 1-2.928 1.924 9.141 9.141 0 0 1-3.454.676Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M250 401a140 140 0 0 0 140-140H110a139.997 139.997 0 0 0 140 140Z"'
            );
            artDataSlot.text = concatenate(artDataSlot.text, ' fill="');
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (
            keccak256(bytes(emotion)) == keccak256(bytes("celebrating"))
        ) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="180" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="180" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><circle cx="320" cy="200" r="35" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><circle cx="320" cy="200" r="28" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path d="M250 401a140 140 0 0 0 140-140H110a139.997 139.997 0 0 0 140 140Z"'
            );
            artDataSlot.text = concatenate(artDataSlot.text, ' fill="');
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)"/><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        } else if (keccak256(bytes(emotion)) == keccak256(bytes("420"))) {
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '<g><g transform="translate('
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M278 203.5c0-6.075 4.925-11 11-11h48c6.075 0 11 4.925 11 11s-4.925 11-11 11h-48c-6.075 0-11-4.925-11-11Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><path d="M278 203.5c0-6.075 4.925-11 11-11h48c6.075 0 11 4.925 11 11s-4.925 11-11 11h-48c-6.075 0-11-4.925-11-11Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><g transform="translate(-'
            );
            artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
            artDataSlot.text = concatenate(
                artDataSlot.text,
                ')"><path d="M148 203.5c0-6.075 4.925-11 11-11h48c6.075 0 11 4.925 11 11s-4.925 11-11 11h-48c-6.075 0-11-4.925-11-11Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 2)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f3)" /><d="M148 203.5c0-6.075 4.925-11 11-11h48c6.075 0 11 4.925 11 11s-4.925 11-11 11h-48c-6.075 0-11-4.925-11-11Z" fill="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 3)]
            );

            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" filter="url(#f2)" /></g><path filter="url(#f2)" d="M140 292.5c5.333 13.167 47 39.5 109.5 39.5s103.833-26.333 109-39.5" stroke-linecap="round" stroke-width="27" fill="none" stroke="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.colorArray[strIndex2num(colors, 4)]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '" /><animateMotion dur="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArray[faceSpeed]
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                '.25s" repeatCount="indefinite" path="'
            );
            artDataSlot.text = concatenate(
                artDataSlot.text,
                artDataSlot.speedArrayTrajectory[faceSpeed]
            );
            artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
            return artDataSlot.text;
        }

        artDataSlot.text = concatenate(
            artDataSlot.text,
            '<g><g transform="translate(-'
        );
        artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
        artDataSlot.text = concatenate(
            artDataSlot.text,
            ')"><circle cx="180" cy="200" r="35" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 2)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" filter="url(#f3)" /><circle cx="180" cy="200" r="28" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 3)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" filter="url(#f2)" /></g><g transform="translate('
        );
        artDataSlot.text = concatenate(artDataSlot.text, eyeDistance);
        artDataSlot.text = concatenate(
            artDataSlot.text,
            ')"><circle cx="320" cy="200" r="35" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 2)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" filter="url(#f3)" /><circle cx="320" cy="200" r="28" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 3)]
        );

        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" filter="url(#f2)" /></g><rect x="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            uint2str(190 - mouthSz)
        );
        artDataSlot.text = concatenate(artDataSlot.text, '" y="300" width="');
        artDataSlot.text = concatenate(
            artDataSlot.text,
            uint2str(120 + (mouthSz * 2))
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" height="40" fill="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.colorArray[strIndex2num(colors, 4)]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '" rx="25" filter="url(#f2)"/><animateMotion dur="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.speedArray[faceSpeed]
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            '.25s" repeatCount="indefinite" path="'
        );
        artDataSlot.text = concatenate(
            artDataSlot.text,
            artDataSlot.speedArrayTrajectory[faceSpeed]
        );
        artDataSlot.text = concatenate(artDataSlot.text, '" /></g></svg>');
        return artDataSlot.text;
    }
}