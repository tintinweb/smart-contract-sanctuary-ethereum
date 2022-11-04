// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "Base64.sol";
import "Strings.sol";
import "IStakefishValidator.sol";
import "Utils.sol";

library NFTRenderer {
    struct RenderParams {
        address walletAddress;
        uint256 validatorIndex;
        bytes validatorPubkey;
        IStakefishValidator.StateChange state;
    }

    function render(RenderParams memory params) public pure returns (string memory) {
        string memory gradientColor1 = "#A6FF9E";
        string memory gradientColor2 = "#9EFF00";
        if(params.state.state != IStakefishValidator.State.Active) {
            gradientColor1 = "#505050";
            gradientColor2 = "#26281D";
        }

        string memory image = string.concat(
            '<svg xmlns="http://www.w3.org/2000/svg" width="290" height="500" fill="none">',
            '<path fill="url(#a)" d="M0 0h290v500H0z"/>',
            '<g clip-path="url(#b)">',
            '<path fill="#000" d="M10 10h262a8 8 0 0 1 8 8v472H18a8 8 0 0 1-8-8V10Z"/>',
            '<path stroke="#fff" stroke-miterlimit="10" stroke-opacity=".25" d="m251.569 285.009 82.22 100.658M230.244 285.009l65.768 100.658M208.917 285.009l49.316 100.658M187.589 285.009l32.865 100.658M166.264 285.009l16.41 100.658M144.936 285.009l-.041 100.658M123.609 285.009l-16.494 100.658M102.284 285.009 69.338 385.667M80.957 285.009 31.559 385.667M59.63 285.009-6.22 385.667M38.304 285.009-44 385.667M251.67 285H38.33M334 385.693H-43.986M317.371 365.354h-344.73M303.431 348.308H-13.422M291.576 333.808H-1.569M281.372 321.328H8.632M272.497 310.473H17.507M264.707 300.946H25.296M257.812 292.513H32.189"/>',
            '<ellipse cx="145" cy="282" fill="url(#c)" fill-opacity=".16" rx="166" ry="116"/>',
            '<path stroke="#fff" stroke-opacity=".25" stroke-width="1.25" d="M201.625 436v47"/>',
            renderTrident(params.state),
            renderTop(params.validatorIndex, params.state),
            renderBottom(params.state, params.validatorPubkey),
            '</g>',
            '<defs>',
            '<radialGradient id="c" cx="0" cy="0" r="1" gradientTransform="matrix(0 116 -166 0 145 282)" gradientUnits="userSpaceOnUse">',
            '<stop stop-color="#BCF000"/>',
            '<stop offset="1" stop-color="#BCF000" stop-opacity="0"/>',
            '</radialGradient>',
            '<linearGradient id="a" x1="-12" x2="301.5" y1="-21" y2="522.5" gradientUnits="userSpaceOnUse">',
            '<stop stop-color="',gradientColor1,'"/>',
            '<stop offset="1" stop-color="',gradientColor2,'" stop-opacity=".58"/>',
            '</linearGradient>',
            '<clipPath id="b">',
            '<path fill="#fff" d="M10 10h262a8 8 0 0 1 8 8v472H18a8 8 0 0 1-8-8V10Z"/>',
            '</clipPath>',
            '</defs>',
            '</svg>'
        );

        string memory description = renderDescription();

        string memory json = string.concat(
            '{"name":"stakefish Validator",',
            '"description":"',
            description,
            '",',
            '"image":"data:image/svg+xml;base64,',
            Base64.encode(bytes(image)),
            '"}'
        );

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        );

    }

    function renderDescription() internal pure returns (string memory description) {
        description = string.concat(
            "Stakefish validator staked 32 ETH, currently in x status. ",
            "Holder of NFT earns protocol rewards, and fee/MEV rewards"
        );
    }

    function renderTrident(
        IStakefishValidator.StateChange memory status
    ) internal pure returns (string memory background) {
        string memory topColor = "#6F7557";
        string memory bottomColor = "#3C4224";

        if(status.state == IStakefishValidator.State.Active) {
            topColor = "#BCF000";
            bottomColor = "#719000";
        }

        background = string.concat(
            '<path fill="',topColor,'" d="M135.803 245.788c2.9-3.1 2.6-7.1 2.8-10.8.5-11.8-.1-23.5-1.7-35.3-.6-4.4-1.9-7.8-6.7-9.3-3.3-1-5.7-3.2-4.3-7.5 5.2-16.5 7.3-33.7 11.1-50.5 1.4-5.9 2.1-12.1 5.2-17.5 3.8-1.1 3.9 2.1 4.5 4.2 1.2 4.5 1.2 9.2 1.5 13.8 1.1 17.6 2.9 35.1 4 52.6.1 2 .1 4.1-.9 5.8-3.7 6.5-3.5 13.7-3.8 20.8-.4 10.6.4 21.2-.9 31.9-.7 5.5-2.5 9.8-8 11.4-3 .9-1.2 2.8-1.6 4.3-9.1-3.2-18.5-3.2-28-2.9-5.3.1-6.2-1.4-4.3-6.3 5.7-14.1 3.9-26.9-6.1-38.5-1.4-1.7-2.4-3.5-2.6-5.8-1.4-13.8-6.5-26.3-12.9-38.4-1.7-3.2-4.2-6-4.1-10 2.4-.5 3.1 1.5 4.1 2.9 11.3 14.2 19.5 30 25.4 47.1 3.9 11.2 7.8 22.3 7.7 34.3 0 3.5 1.8 5.2 5.4 4.7 4.8-.6 9.7 2.2 14.2-1Z"/>',
            '<path fill="',bottomColor,'" d="M136.903 259.788c-.7-2.1-3.3-2.1-4.5-3.6.7-1.7 2.2-1.3 3.4-1.5 5.8-.6 8.5-3.6 9.1-9.2 1.2-9.9 1-19.9.9-29.8-.1-6.2 1.1-12.2 1.1-18.4 0-.7-.1-1.5.3-1.9 6.9-8 2.2-17.3 2.2-25.8 0-10.7-1.6-21.4-2.5-32.1-.5-6.4-.8-12.9-1.9-19.2-.3-1.8-.6-3.3-2.9-3.3 2.7-4 4-4 5.9.1 3.7 7.7 4.9 16.2 6.7 24.4 3.2 14.4 5.3 29.1 9.8 43.2 1.3 4-.6 6.6-4.1 7.8-4.8 1.6-6.5 4.9-7.1 9.6-1.7 13.3-1.8 26.5-.4 39.8.6 5.3 1.8 6.2 7.1 5.9 3.6-.2 7.3-.6 10.9-.9.1 3.2-2.2 3.7-4.6 4.1-1.9.4-4-.2-6.9 1 4.3 0 7.6-.5 10.9-.7 2.8-.2 4.1-1.9 4.2-4.7.8-23.5 11.8-43.6 21.3-64.2.9-1.9 1.9-3.9 4.2-4.8 2.6 1.2 1.1 2.9.5 4.5-2.7 7.1-5.5 14.1-7 21.7-.6 3.1 1.8 6.3-.4 9.2-11.2 11.3-12.9 24.4-7.2 38.9.1.3.3.6.4.9 2.3 5.9 1.6 6.9-4.9 6.9-4.2 0-8.3-.1-12.5 0-2.8.1-5.6.2-8.4.9-4.1 1-7.9 2.1-6.3 7.8.6 2.2-1 3.8-2.7 4.9-1.8 1.1-2.6 2.7-2.2 4.6 2 9-1.2 17.8-.7 26.8.2 3.6.6 7.3.5 10.9-.2 6.4-.9 12.8-1.5 19.2-.1 1.1.2 3.2-1.7 3-1.6-.1-1.2-2.1-1.7-3.2-1.5-3.3.5-6.5-.3-9.7-.9-5 .1-9.9.2-14.9.1-9.8.3-19.7-.7-29.4-.8-6.6-.1-14.2-6.5-18.8Z"/>',
            '<path fill="',topColor,'" d="M199.903 175.788c-6.8 11.6-12 23.9-16.5 36.7-2.6 7.3-5.5 14.5-7.1 22.1-.7 3.5-.4 7-.4 10.4.1 3.5-1.6 5.4-4.9 5.6-3.7.2-7.3.3-10.9 1-1.1.3-3 .5-3.1-1.4-.1-1.9 1.4-2.5 3-2.5 1.8 0 3.7-.1 5.5 0 2.4.1 4.2-.7 5.3-2.9 1-.9 1.8-1.9 1.6-3.4-2.1-13.3 2.1-25.7 6.5-37.9 3.5-9.7 7.9-19 13.6-27.7 3.9-3.9 6.1-9 10.1-12.8 1-.9 1.7-2 2.9-2.7.7-.4 1.4-1 2.3-.4.8.5.9 1.4.6 2.2-2.4 4.8-3.9 10.2-8.5 13.7Z"/>',
            '<path fill="',bottomColor,'" d="M135.803 245.787c-1.1 2.1-2.8 3-5.3 2.9-3.6-.1-7.1-1-10.8-.3-2.7.5-4.7-1.5-4.9-4.9-1.5-29.3-13.3-54.7-30.1-78.2-1.8-2.5-3-5.6-5.7-7.4.8-4.6 3.2-2.7 5.1-1 4 3.6 6.9 8 9.9 12.5 12.2 18.2 19.4 38.4 24.2 59.6.8 3.4.8 7 .6 10.4-.2 3.5 1.5 4.9 4.6 5.2 4.1.5 8.3.8 12.4 1.2Z"/>',
            '<path fill="',topColor,'" d="M136.803 259.788c4.7.5 6.6 3 6.1 7.8-.3 2.7-.6 5.7 1.9 7.9.8.6.3 1.5.3 2.3-.1 11.6.1 35.3-.3 46.9-.1 3.3.2 7.2 0 10.5-1.7-3.4-2.7-7.7-2.4-11.1.7-9.4.9-30.7-1.1-40-.4-1.6-.2-3.3.3-4.9.9-3.5.9-6.8-2.5-9.2-1.5-1.1-2.2-2.9-1.5-4.9.6-2 .1-3.7-.8-5.3Z"/>',
            '<path fill="',bottomColor,'" d="M199.903 175.787c2.2-5.2 6.4-9.4 8.3-16.1-5.6 3.9-8.9 8.401-12.3 12.801-1 1.3-1.8 2.799-3.5 3.299 3.3-6.2 7.2-11.9 12.1-17 1.3-1.4 2.9-3.5 5-2 2 1.5.5 3.7-.3 5.4-4 8.4-8 16.8-11 25.6-2.2 6.4-5 12.7-3.6 19.7.3 1.4-.1 2.7-1.6 3.3-2.2-11.2 3.1-20.7 6.6-30.7.5-1.3 2.2-2.7.3-4.3Z"/>'
        );
    }

    function renderIndex(uint256 validatorIndex) internal pure returns (string memory index) {
        if(validatorIndex == 0) {
            index = "N/A";
        } else {
            index = string.concat('#',Strings.toString(validatorIndex));
        }
    }

    function renderETH(IStakefishValidator.StateChange memory status) internal pure returns (string memory) {
        if(status.state == IStakefishValidator.State.Withdrawn) {
            return "0";
        }
        return "32";
    }

    function renderReward(IStakefishValidator.StateChange memory status) internal pure returns (string memory) {
        if(status.state == IStakefishValidator.State.Active) {
            return "5.5%";
        }
        return "0%";
    }

    function renderTop(
        uint256 validatorIndex,
        IStakefishValidator.StateChange memory state
    ) internal pure returns (string memory top) {
        top = string.concat(
            '<path stroke="#fff" stroke-opacity=".25" d="M20 62.5h250"/>',
            '<text xml:space="preserve" fill="#fff" fill-opacity=".65" font-family="Arial" font-size="6" font-weight="600" letter-spacing="1" style="white-space:pre"><tspan x="216.269" y="30.682">VALIDATOR</tspan></text>',
            '<text xml:space="preserve" fill="#fff" font-family="Courier" font-size="12" letter-spacing="0" style="white-space:pre"><tspan x="215.414" y="45.656">',renderIndex(validatorIndex), '</tspan></text>',
            '<path stroke="#fff" stroke-opacity=".25" stroke-width="1.25" d="M201.625 22v30"/>',
            '<text xml:space="preserve" fill="#fff" font-family="Arial" font-size="34" font-weight="800" letter-spacing="-2" style="white-space:pre"><tspan x="21" y="47.864">', renderETH(state),'</tspan></text>',
            '<text xml:space="preserve" fill="#BCF000" font-family="Arial" font-size="34" font-weight="800" letter-spacing="-2" style="white-space:pre"><tspan x="67" y="47.864">ETH</tspan></text>',
            '<text xml:space="preserve" fill="#fff" fill-opacity=".65" font-family="Arial" font-size="7" font-weight="600" letter-spacing="1.5" style="white-space:pre"><tspan x="145" y="28.546">REWARD</tspan></text>',
            '<text xml:space="preserve" fill="#fff" font-family="Arial" font-size="18" font-weight="800" letter-spacing="-.996" style="white-space:pre"><tspan x="145" y="47.545">',renderReward(state),'</tspan></text>'
        );
    }

    function renderStatus(IStakefishValidator.StateChange memory status) internal pure returns (string memory rendered) {
        if(status.state == IStakefishValidator.State.PreDeposit) {
            return "Depositing";
        }
        else if(status.state == IStakefishValidator.State.PostDeposit) {
            return "Pending";
        }
        else if(status.state == IStakefishValidator.State.Active) {
            return "Active";
        }
        else if(status.state == IStakefishValidator.State.ExitRequested) {
            return "Exit Requested";
        }
        else if(status.state == IStakefishValidator.State.Exited) {
            return "Exited";
        }
        else if(status.state == IStakefishValidator.State.Withdrawn) {
            return "Withdrawn";
        }
    }

    /// @notice index when equals zero, show the first 16 bytes, 1 shows the next 16 bytes..
    /// pubkey is 48 bytes / 3
    function renderPubkey(bytes memory pubkey, uint8 index) internal pure returns (string memory) {
        uint128 part = uint128(bytes16(Utils.slice(pubkey, 16*index, 16)));
        return Utils.toHexStringNoPrefix(part, 16);
    }

    function renderDate(IStakefishValidator.StateChange memory status) internal pure returns (string memory) {
        if(status.state == IStakefishValidator.State.Active) {
            return Strings.toString(status.changedAt);
        } else {
            return "N/A";
        }
    }

    function renderBottom(IStakefishValidator.StateChange memory status, bytes memory pubkey)
        internal
        pure
        returns (string memory bottom)
    {
        bottom = string.concat(
            '<text xml:space="preserve" fill="#fff" fill-opacity=".65" font-family="Arial" font-size="7" font-weight="600" letter-spacing="1.5" style="white-space:pre"><tspan x="22" y="400.545">STATUS</tspan></text>',
            '<text xml:space="preserve" fill="#fff" font-family="Courier" font-size="10" letter-spacing="0" style="white-space:pre"><tspan x="22" y="416.88">', renderStatus(status),'</tspan></text>',
            '<text xml:space="preserve" fill="#fff" fill-opacity=".65" font-family="Arial" font-size="7" font-weight="600" letter-spacing="1.5" style="white-space:pre"><tspan x="125" y="400.545">ACTIVE DATE</tspan></text>',
            '<text xml:space="preserve" fill="#fff" font-family="Courier" font-size="10" letter-spacing="0" style="white-space:pre"><tspan x="125" y="416.88">', renderDate(status),'</tspan></text>',
            '<path fill="#fff" fill-opacity=".25" d="M270 427H20v2h250v-2Z" mask="url(#path-24-outside-1_107_63)"/>',
            '<path fill="#fff" d="M247.964 465.602a.76.76 0 0 0 .509-.174.625.625 0 0 0 .207-.472.546.546 0 0 0-.207-.457.764.764 0 0 0-.509-.173.768.768 0 0 0-.509.173.58.58 0 0 0-.191.457c0 .189.064.346.191.472a.763.763 0 0 0 .509.174Z"/>',
            '<path fill="#fff" d="M248.028 466.342h-2.497v-.142c0-.252.063-.456.175-.582.111-.127.302-.205.556-.237l.191-.016a.496.496 0 0 0 .318-.141.448.448 0 0 0 .128-.331c0-.205-.096-.457-.525-.457-.064 0-.112 0-.143.016l-.207.016c-.541.047-.97.236-1.272.567-.303.33-.446.772-.446 1.307h-.381c-.462 0-.557.252-.557.473 0 .22.095.472.557.472h.381v2.914c0 .189.064.331.175.425a.639.639 0 0 0 .43.142.636.636 0 0 0 .429-.142c.111-.094.175-.236.175-.425v-2.914h1.829v2.914c0 .189.064.331.175.425a.636.636 0 0 0 .429.142.582.582 0 0 0 .43-.157.556.556 0 0 0 .175-.426v-3.386c.016-.189-.08-.457-.525-.457ZM252.942 468.799c-.095-.173-.27-.299-.509-.409-.222-.111-.54-.205-.938-.284-.366-.079-.604-.142-.731-.22a.3.3 0 0 1-.16-.284c0-.126.048-.236.16-.315.111-.079.27-.126.477-.126.175 0 .318.016.445.063s.27.11.429.189c.096.047.175.095.239.126a.487.487 0 0 0 .207.047.364.364 0 0 0 .286-.141.49.49 0 0 0 .111-.331c0-.205-.111-.378-.302-.504a2.084 2.084 0 0 0-.636-.268 2.826 2.826 0 0 0-.732-.094c-.35 0-.668.063-.938.173-.27.11-.493.283-.652.504a1.2 1.2 0 0 0-.239.724c0 .347.128.63.366.835.239.205.62.347 1.145.457.287.063.509.126.652.173a.822.822 0 0 1 .271.142c.047.047.063.11.063.189 0 .126-.063.22-.175.283-.127.079-.318.111-.54.111-.239 0-.43-.016-.573-.063a5.77 5.77 0 0 1-.509-.189c-.191-.095-.334-.142-.445-.142a.396.396 0 0 0-.286.126.425.425 0 0 0-.112.315c0 .22.112.394.302.52.398.252.939.378 1.575.378.557 0 1.018-.126 1.352-.362.35-.253.525-.583.525-.993a.984.984 0 0 0-.128-.63ZM256.41 466.248c-.319 0-.605.063-.859.189-.191.094-.366.22-.493.393v-1.858c0-.174-.064-.3-.175-.394a.64.64 0 0 0-.43-.142c-.175 0-.334.047-.445.158a.544.544 0 0 0-.175.409v5.198c0 .173.048.315.159.425.111.111.255.158.445.158.191 0 .334-.047.446-.158a.58.58 0 0 0 .175-.425v-1.937c0-.315.095-.567.27-.756.175-.189.414-.284.716-.284.254 0 .429.063.556.189.112.126.175.347.175.63v2.158a.58.58 0 0 0 .175.425c.112.111.255.158.446.158.19 0 .334-.047.445-.158a.568.568 0 0 0 .159-.425v-2.142c-.032-1.213-.557-1.811-1.59-1.811ZM221.626 468.799c-.095-.173-.27-.299-.509-.409-.222-.111-.54-.205-.938-.284-.366-.079-.604-.142-.732-.22a.3.3 0 0 1-.159-.284c0-.126.048-.236.159-.315.112-.079.271-.126.477-.126.175 0 .319.016.446.063s.27.11.429.189c.096.047.175.095.239.126a.484.484 0 0 0 .207.047.364.364 0 0 0 .286-.141.495.495 0 0 0 .111-.331c0-.205-.111-.378-.302-.504a2.094 2.094 0 0 0-.636-.268 2.826 2.826 0 0 0-.732-.094c-.35 0-.668.063-.938.173-.271.11-.493.283-.652.504a1.2 1.2 0 0 0-.239.724c0 .347.127.63.366.835.239.205.62.347 1.145.457.286.063.509.126.652.173a.833.833 0 0 1 .271.142c.047.047.063.11.063.189 0 .126-.063.22-.175.283-.127.079-.318.111-.541.111-.238 0-.429-.016-.572-.063a5.77 5.77 0 0 1-.509-.189c-.191-.095-.334-.142-.445-.142a.4.4 0 0 0-.287.126.429.429 0 0 0-.111.315c0 .22.111.394.302.52.398.252.939.378 1.575.378.556 0 1.018-.126 1.352-.362.35-.253.524-.583.524-.993.016-.252-.031-.472-.127-.63ZM224.918 469.854l-.238-.015c-.366-.032-.541-.237-.541-.63v-1.922h.684a.703.703 0 0 0 .398-.11.44.44 0 0 0 .143-.347c0-.157-.048-.267-.143-.346-.096-.079-.239-.11-.398-.11h-.684v-.741a.52.52 0 0 0-.175-.409.575.575 0 0 0-.429-.158c-.191 0-.334.047-.446.158a.544.544 0 0 0-.175.409v.741h-.381a.703.703 0 0 0-.398.11.44.44 0 0 0-.143.346c0 .158.048.268.143.347.096.079.223.11.398.11h.381v1.843c0 1.008.509 1.559 1.527 1.622l.239.016h.079c.175 0 .334-.031.43-.11a.403.403 0 0 0 .191-.362c.031-.19-.048-.426-.462-.442ZM229.292 466.704c-.302-.299-.763-.456-1.367-.456a3.98 3.98 0 0 0-.859.094 2.959 2.959 0 0 0-.748.268.654.654 0 0 0-.27.22c-.064.079-.08.174-.08.284 0 .142.032.252.112.331.079.094.175.126.302.126.079 0 .191-.032.35-.111.238-.094.445-.157.62-.204.175-.048.334-.079.509-.079.254 0 .445.063.557.173.111.126.174.315.174.583v.142h-.159c-.636 0-1.145.047-1.51.126-.382.078-.653.22-.812.409-.175.189-.254.457-.254.772 0 .268.064.504.207.709.143.205.334.378.572.504.239.126.509.173.811.173.287 0 .557-.063.78-.205.159-.094.286-.22.381-.362a.52.52 0 0 0 .159.378.57.57 0 0 0 .414.158.579.579 0 0 0 .429-.158c.112-.094.159-.236.159-.41v-2.126c-.031-.567-.19-1.039-.477-1.339Zm-.715 2.079v.126c0 .284-.096.536-.255.709-.175.189-.397.268-.668.268-.175 0-.334-.047-.445-.158a.513.513 0 0 1-.175-.409c0-.142.048-.236.127-.315.08-.079.239-.142.43-.173a6.52 6.52 0 0 1 .906-.048h.08ZM234.668 469.776l-1.479-1.323 1.336-1.229c.127-.126.191-.252.191-.409a.62.62 0 0 0-.159-.394.534.534 0 0 0-.398-.158.572.572 0 0 0-.398.174l-1.813 1.701v-3.135c0-.189-.063-.331-.175-.425a.636.636 0 0 0-.429-.142.64.64 0 0 0-.43.142c-.111.094-.175.236-.175.425v5.198c0 .189.064.331.175.425a.64.64 0 0 0 .43.142.636.636 0 0 0 .429-.142c.112-.094.175-.236.175-.425v-1.355l1.956 1.765c.128.11.255.173.398.173a.54.54 0 0 0 .382-.173.547.547 0 0 0 .159-.394.526.526 0 0 0-.175-.441ZM238.946 469.445c-.095 0-.222.047-.413.142a5.433 5.433 0 0 1-.477.189 1.537 1.537 0 0 1-.478.063c-.349 0-.62-.095-.811-.268-.175-.173-.286-.425-.318-.788h2.529c.175 0 .398-.078.398-.425 0-.425-.08-.803-.239-1.118a1.82 1.82 0 0 0-.684-.74 2.052 2.052 0 0 0-1.034-.268c-.413 0-.795.094-1.113.283a1.87 1.87 0 0 0-.763.804c-.175.346-.271.74-.271 1.181 0 .693.207 1.26.621 1.669.413.41.986.615 1.685.615.239 0 .478-.032.732-.095.255-.063.493-.157.684-.267.239-.126.35-.3.35-.505a.507.507 0 0 0-.111-.346.4.4 0 0 0-.287-.126Zm-.636-1.355h-1.861c.048-.299.143-.535.302-.708.159-.174.398-.268.668-.268.287 0 .493.079.637.252.159.173.238.409.254.724Z"/>',
            '<path fill="#fff" fill-rule="evenodd" d="M241.634 467.76c.398.047.7.409.652.819a.747.747 0 0 1-.827.645.746.746 0 0 1-.652-.724.73.73 0 0 1 .748-.725c.032-.031.047-.031.079-.015ZM242.254 447a7.1 7.1 0 0 0-5.359 2.41 8.223 8.223 0 0 1 3.928 1.843c.779.63 1.463 1.37 2.052 2.189l.334.488c.063.079.063.174-.016.268l-.334.488a10.792 10.792 0 0 1-2.052 2.19 8.222 8.222 0 0 1-3.912 1.827 7.155 7.155 0 0 0 5.359 2.41c3.929 0 7.126-3.166 7.126-7.057 0-3.89-3.181-7.056-7.126-7.056Z" clip-rule="evenodd"/>',
            '<path fill="#fff" fill-rule="evenodd" d="M235.956 457.333h.112c2.703-.189 4.596-2.127 5.423-3.151.064-.078.064-.173 0-.236-.811-1.024-2.72-2.961-5.423-3.15h-.112a7.025 7.025 0 0 0-.811 3.26 6.72 6.72 0 0 0 .811 3.277Zm2.847-3.985c.032-.016.048-.016.08-.016.397.047.7.409.652.819a.749.749 0 0 1-.827.646.748.748 0 0 1-.652-.725.73.73 0 0 1 .747-.724Z" clip-rule="evenodd"/>',
            '<path fill="#fff" fill-rule="evenodd" d="M229.61 454.167a.164.164 0 0 1 0-.205c1.67-2.063 3.976-3.276 6.33-3.166.27-.504.589-.961.955-1.386a6.454 6.454 0 0 0-.764-.095 8.63 8.63 0 0 0-6.012 2.079c-.509.41-.97.867-1.384 1.371h-.016c-.031.016-.063.016-.079-.016a12.34 12.34 0 0 1-1.113-2.63v-.016a.756.756 0 0 0-.43-.425.64.64 0 0 0-.509.015.78.78 0 0 0-.397.835v.016a12.796 12.796 0 0 0 1.511 3.402.204.204 0 0 1 0 .189 12.673 12.673 0 0 0-1.511 3.418v.032a.775.775 0 0 0 .731.771.698.698 0 0 0 .589-.33l.016-.016v-.016c.27-.913.636-1.811 1.113-2.63v-.016c.016-.016.063-.032.079 0 .414.504.891.961 1.384 1.37a8.73 8.73 0 0 0 5.519 2.111c.159 0 .334 0 .493-.016.27-.016.525-.063.78-.11a8.12 8.12 0 0 1-.955-1.37c-2.338.11-4.644-1.103-6.33-3.166Z" clip-rule="evenodd"/>',
            '<text xml:space="preserve" fill="#fff" fill-opacity=".65" font-family="Arial" font-size="7" font-weight="600" letter-spacing="1.5" style="white-space:pre"><tspan x="22" y="443.545">PUBLIC KEY</tspan></text>',
            '<text xml:space="preserve" fill="#fff" font-family="Courier" font-size="8" letter-spacing="0" style="white-space:pre"><tspan x="22" y="457.354">', renderPubkey(pubkey, 0),'</tspan><tspan x="22" y="467.854">', renderPubkey(pubkey, 1),'</tspan><tspan x="22" y="478.354">', renderPubkey(pubkey, 2),'</tspan></text>'
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title The interface for StakefishValidator
/// @notice Defines implementation of the wallet (deposit, withdraw, collect fees)
interface IStakefishValidator {

    event StakefishValidatorDeposited(bytes validatorPubKey);
    event StakefishValidatorExitRequest(bytes validatorPubKey);
    event StakefishValidatorStarted(bytes validatorPubKey, uint256 startTimestamp);
    event StakefishValidatorExited(bytes validatorPubKey, uint256 stopTimestamp);
    event StakefishValidatorWithdrawn(bytes validatorPubKey, uint256 amount);
    event StakefishValidatorCommissionTransferred(bytes validatorPubKey, uint256 amount);
    event StakefishValidatorFeePoolChanged(bytes validatorPubKey, address feePoolAddress);

    enum State { PreDeposit, PostDeposit, Active, ExitRequested, Exited, Withdrawn }

    /// @dev aligns into 32 byte
    struct StateChange {
        State state;            // 1 byte
        bytes15 userData;       // 15 byte (future use)
        uint128 changedAt;      // 16 byte
    }

    /// @notice initializer
    function setup() external;

    function validatorIndex() external view returns (uint256);
    function pubkey() external view returns (bytes memory);

    /// @notice Inspect state of the change
    function lastStateChange() external view returns (StateChange memory);

    /// @notice Submits a Phase 0 DepositData to the eth2 deposit contract.
    /// @dev https://github.com/ethereum/consensus-specs/blob/master/solidity_deposit_contract/deposit_contract.sol#L33
    /// @param validatorPubKey A BLS12-381 public key.
    /// @param depositSignature A BLS12-381 signature.
    /// @param depositDataRoot The SHA-256 hash of the SSZ-encoded DepositData object.
    function makeEth2Deposit(
        bytes calldata validatorPubKey, // 48 bytes
        bytes calldata depositSignature, // 96 bytes
        bytes32 depositDataRoot
    ) external;

    /// @notice Operator updates the start state of the validator
    /// Updates validator state to running
    /// State.PostDeposit -> State.Running
    function validatorStarted(
        uint256 _startTimestamp,
        uint256 _validatorIndex,
        address _feePoolAddress) external;

    /// @notice Operator updates the exited from beaconchain.
    /// State.ExitRequested -> State.Exited
    /// emit ValidatorExited(pubkey, stopTimestamp);
    function validatorExited(uint256 _stopTimestamp) external;

    /// @notice NFT Owner requests a validator exit
    /// State.Running -> State.ExitRequested
    /// emit ValidatorExitRequest(pubkey)
    function requestExit() external;

    /// @notice user withdraw balance and charge a fee
    function withdraw() external;

    /// @notice ability to change fee pool
    function validatorFeePoolChange(address _feePoolAddress) external;

    /// @notice get pending fee pool rewards
    function pendingFeePoolReward() external view returns (uint256, uint256);

    /// @notice claim fee pool and forward to nft owner
    function claimFeePool(uint256 amountRequested) external;

    function render() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Utils {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    /* @notice              Slice the _bytes from _start index till the result has length of _length
                            Refer from https://github.com/summa-tx/bitcoin-spv/blob/master/solidity/contracts/BytesLib.sol#L246
    *  @param _bytes        The original bytes needs to be sliced
    *  @param _start        The index of _bytes for the start of sliced bytes
    *  @param _length       The index of _bytes for the end of sliced bytes
    *  @return              The sliced bytes
    */
    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                // lengthmod <= _length % 32
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}