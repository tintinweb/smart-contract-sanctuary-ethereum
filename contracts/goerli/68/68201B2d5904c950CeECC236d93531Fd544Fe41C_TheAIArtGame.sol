//Contract based on [https://docs.openzeppelin.com/contracts/3.x/erc721](https://docs.openzeppelin.com/contracts/3.x/erc721)
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./ERC721A.sol";
import "./NEURAL/NEURAL.sol";

//import "./onChainArcade_Snake_Art.sol";

//            //////////////////////////////////////////////////////////////////////////
//            //           ______________________                    _________        //
//           //           __  __ \_  ____/__    |__________________ ______  /____    //
//          //           _  / / /  /    __  /| |_  ___/  ___/  __ `/  __  /_  _ \   //
//          //           / /_/ // /___  _  ___ |  /   / /__ / /_/ // /_/ / /  __/   //
//          //           \____/ \____/  /_/  |_/_/    \___/ \__,_/ \__,_/  \___/    //
//          //                                                                      //
//          //              ▀█▀ █▀▀ █▀▀ █ █ █▄ █ █▀█ █▀▄▀█ ▄▀█ █▄ █ █▀▀ █▄█         //
//          //               █  ██▄ █▄▄ █▀█ █ ▀█ █▄█ █ ▀ █ █▀█ █ ▀█ █▄▄  █          //
//          //                                                                      //
//                                                                                  /////////////////////

////////////////////////////////////////////////////////////////////////////////////////////////////////
contract TheAIArtGame is Ownable, ERC2981, ERC721A, ReentrancyGuard {
    //apple string

    struct MaintenanceDudes {
        uint256 itemType;
        bool canWithdraw;
        bool monthlyReset;
        uint256 lastWithDraw;
        uint256 withDrawAmount;
        uint256 royalities;
    }

    struct Attributes {
        string trait_type;
        string value;
    }

    struct VerifiedMessage {
        uint256[4] message;
        SignatureInfo signature;
    }

    struct SignatureInfo {
        uint8 _v;
        bytes32 _r;
        bytes32 _s;
    }

    struct AttributesNumbers {
        string trait_type;
        string display_type;
        uint256 value;
        uint256 max;
    }

    struct TokenInfo {
        uint256 date;
        uint256 claimDate;
    }

    bool private wordGeneration = true;
    bool private unhideWord = true;
    address private arcadeOwner;
    string private seed = "beforerevealtestanothertest";

    NEURAL token;

    mapping(uint256 => TokenInfo) public tokenInfo;
    mapping(address => uint256) private maxMint;
    mapping(address => MaintenanceDudes) private arcadeDudes;

    string[7] private wordStyle = [
        "Blur",
        "Mirror Display",
        "Split",
        "Fat Stripes",
        "Jump Split",
        "Hangin Chad",
        "Shadow Pop"
    ];

    string[5] private metadata = [
        '{"name": "',
        '", "description": "This is a game utilizing OpenAI Doll-E engine and the blockchain. Will you generate beautiful art, or will it just be crazy? This word is waiting to reveal.", "animation_url": "',
        '","external_url":"https://aiblockchain.game/',
        '","image":"',
        "}"
    ];

    string[1] private mirrorDisplay = [
        '<html><style>*, *::before, *::after{padding: 0; margin: 0 auto; box-sizing: border-box;}body{background-color: black; height: 100vh; display: grid; grid-template: repeat(15, 1fr)/repeat(15, 1fr); overflow: hidden;}.cell{width: 100%; height: 100%; z-index: 2;}.cell:nth-child(15n+1):hover~.content{--positionX: 0;}.cell:nth-child(n+1):nth-child(-n+15):hover~.content{--positionY: 0;}.cell:nth-child(15n+2):hover~.content{--positionX: 1;}.cell:nth-child(n+16):nth-child(-n+30):hover~.content{--positionY: 1;}.cell:nth-child(15n+3):hover~.content{--positionX: 2;}.cell:nth-child(n+31):nth-child(-n+45):hover~.content{--positionY: 2;}.cell:nth-child(15n+4):hover~.content{--positionX: 3;}.cell:nth-child(n+46):nth-child(-n+60):hover~.content{--positionY: 3;}.cell:nth-child(15n+5):hover~.content{--positionX: 4;}.cell:nth-child(n+61):nth-child(-n+75):hover~.content{--positionY: 4;}.cell:nth-child(15n+6):hover~.content{--positionX: 5;}.cell:nth-child(n+76):nth-child(-n+90):hover~.content{--positionY: 5;}.cell:nth-child(15n+7):hover~.content{--positionX: 6;}.cell:nth-child(n+91):nth-child(-n+105):hover~.content{--positionY: 6;}.cell:nth-child(15n+8):hover~.content{--positionX: 7;}.cell:nth-child(n+106):nth-child(-n+120):hover~.content{--positionY: 7;}.cell:nth-child(15n+9):hover~.content{--positionX: 8;}.cell:nth-child(n+121):nth-child(-n+135):hover~.content{--positionY: 8;}.cell:nth-child(15n+10):hover~.content{--positionX: 9;}.cell:nth-child(n+136):nth-child(-n+150):hover~.content{--positionY: 9;}.cell:nth-child(15n+11):hover~.content{--positionX: 10;}.cell:nth-child(n+151):nth-child(-n+165):hover~.content{--positionY: 10;}.cell:nth-child(15n+12):hover~.content{--positionX: 11;}.cell:nth-child(n+166):nth-child(-n+180):hover~.content{--positionY: 11;}.cell:nth-child(15n+13):hover~.content{--positionX: 12;}.cell:nth-child(n+181):nth-child(-n+195):hover~.content{--positionY: 12;}.cell:nth-child(15n+14):hover~.content{--positionX: 13;}.cell:nth-child(n+196):nth-child(-n+210):hover~.content{--positionY: 13;}.cell:nth-child(15n+15):hover~.content{--positionX: 14;}.cell:nth-child(n+211):nth-child(-n+225):hover~.content{--positionY: 14;}.content{--positionX: 7; --positionY: 7; position: absolute; top: 0; right: 0; bottom: 0; left: 0; display: flex; justify-content: center; align-items: center;}.css{font-family: "Fredoka One", cursive; position: absolute; top: 50%; left: 50%; -webkit-animation: color 3s infinite linear; animation: color 3s infinite linear; text-shadow: 0 0 10px #000a; transition: all 0.5s;}.css:nth-child(1){font-size: 100px; -webkit-animation-delay: 0s; animation-delay: 0s; opacity: 0.1; transform: translateX(calc(-50% - (var(--positionX) - 7) * 21px)) translateY(calc(-50% - (var(--positionY) - 7) * 21px)) rotateX(calc(0deg - (var(--positionY) - 7) * 5deg)) rotateY(calc((var(--positionX) - 7) * 5deg));}.css:nth-child(2){font-size: 110px; -webkit-animation-delay: -0.3s; animation-delay: -0.3s; opacity: 0.2; transform: translateX(calc(-50% - (var(--positionX) - 7) * 18px)) translateY(calc(-50% - (var(--positionY) - 7) * 18px)) rotateX(calc(0deg - (var(--positionY) - 7) * 5deg)) rotateY(calc((var(--positionX) - 7) * 5deg));}.css:nth-child(3){font-size: 120px; -webkit-animation-delay: -0.6s; animation-delay: -0.6s; opacity: 0.3; transform: translateX(calc(-50% - (var(--positionX) - 7) * 15px)) translateY(calc(-50% - (var(--positionY) - 7) * 15px)) rotateX(calc(0deg - (var(--positionY) - 7) * 5deg)) rotateY(calc((var(--positionX) - 7) * 5deg));}.css:nth-child(4){font-size: 130px; -webkit-animation-delay: -0.9s; animation-delay: -0.9s; opacity: 0.4; transform: translateX(calc(-50% - (var(--positionX) - 7) * 12px)) translateY(calc(-50% - (var(--positionY) - 7) * 12px)) rotateX(calc(0deg - (var(--positionY) - 7) * 5deg)) rotateY(calc((var(--positionX) - 7) * 5deg));}.css:nth-child(5){font-size: 140px; -webkit-animation-delay: -1.2s; animation-delay: -1.2s; opacity: 0.5; transform: translateX(calc(-50% - (var(--positionX) - 7) * 9px)) translateY(calc(-50% - (var(--positionY) - 7) * 9px)) rotateX(calc(0deg - (var(--positionY) - 7) * 5deg)) rotateY(calc((var(--positionX) - 7) * 5deg));}.css:nth-child(6){font-size: 150px; -webkit-animation-delay: -1.5s; animation-delay: -1.5s; opacity: 0.6; transform: translateX(calc(-50% - (var(--positionX) - 7) * 6px)) translateY(calc(-50% - (var(--positionY) - 7) * 6px)) rotateX(calc(0deg - (var(--positionY) - 7) * 5deg)) rotateY(calc((var(--positionX) - 7) * 5deg));}.css:nth-child(7){font-size: 160px; -webkit-animation-delay: -1.8s; animation-delay: -1.8s; opacity: 0.7; transform: translateX(calc(-50% - (var(--positionX) - 7) * 3px)) translateY(calc(-50% - (var(--positionY) - 7) * 3px)) rotateX(calc(0deg - (var(--positionY) - 7) * 5deg)) rotateY(calc((var(--positionX) - 7) * 5deg));}.css:nth-child(8){font-size: 170px; -webkit-animation-delay: -2.1s; animation-delay: -2.1s; opacity: 0.8; transform: translateX(calc(-50% - (var(--positionX) - 7) * 0px)) translateY(calc(-50% - (var(--positionY) - 7) * 0px)) rotateX(calc(0deg - (var(--positionY) - 7) * 5deg)) rotateY(calc((var(--positionX) - 7) * 5deg));}.css:nth-child(9){font-size: 180px; -webkit-animation-delay: -2.4s; animation-delay: -2.4s; opacity: 0.9; transform: translateX(calc(-50% - (var(--positionX) - 7) * -3px)) translateY(calc(-50% - (var(--positionY) - 7) * -3px)) rotateX(calc(0deg - (var(--positionY) - 7) * 5deg)) rotateY(calc((var(--positionX) - 7) * 5deg));}.css:nth-child(10){font-size: 190px; -webkit-animation-delay: -2.7s; animation-delay: -2.7s; opacity: 1; transform: translateX(calc(-50% - (var(--positionX) - 7) * -6px)) translateY(calc(-50% - (var(--positionY) - 7) * -6px)) rotateX(calc(0deg - (var(--positionY) - 7) * 5deg)) rotateY(calc((var(--positionX) - 7) * 5deg));}@-webkit-keyframes color{0%{color: #ef8f8f;}10%{color: #efc98f;}20%{color: #dcef8f;}30%{color: #a3ef8f;}40%{color: #8fefb6;}50%{color: #8fefef;}60%{color: #8fb6ef;}70%{color: #a38fef;}80%{color: #dc8fef;}90%{color: #ef8fc9;}100%{color: #ef8f8f;}}@keyframes color{0%{color: #ef8f8f;}10%{color: #efc98f;}20%{color: #dcef8f;}30%{color: #a3ef8f;}40%{color: #8fefb6;}50%{color: #8fefef;}60%{color: #8fb6ef;}70%{color: #a38fef;}80%{color: #dc8fef;}90%{color: #ef8fc9;}100%{color: #ef8f8f;}}</style>'
    ];

    string[2] private fatStripe = [
        '<html><style>html{height: 100%;}body{width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-family: "Bungee Shade", cursive; background: #ffed94;}h1{display: flex; align-items: center; justify-content: center; align-content: center; text-align: center; font-weight: normal; width: 100%; text-align: center; font-size: 16vw; background: linear-gradient(-45deg, #4bc0c8 25%, #feac5e 25%, #feac5e 50%, #4bc0c8 50%, #4bc0c8 75%, #feac5e 75%, #feac5e); -webkit-background-clip: text; -webkit-text-fill-color: transparent; background-size: 20px 20px; background-position: 0 0; -webkit-animation: stripes 1s linear infinite; animation: stripes 1s linear infinite;}@-webkit-keyframes stripes{100%{background-position: 20px 0, 20px 0, 20px 0;}}@keyframes stripes{100%{background-position: 20px 0, 20px 0, 20px 0;}}</style><h1>',
        "</h1></html>"
    ];

    string[2] private jumpSplit = [
        '<html><style>*,:before,:after{box-sizing: border-box;}body{background-color: #fdf9fd; color: #011a32; font: 16px/1.25 "Raleway", sans-serif; text-align: center;}#wrapper{margin-left: auto; margin-right: auto; max-width: 80em;}#container{display: flex; flex-direction: column; float: left; justify-content: center; min-height: 100vh; padding: 1em; width: 100%;}h1{animation: text-shadow 1.5s ease-in-out infinite; font-size: 5em; font-weight: 900; line-height: 1;}h1:hover{animation-play-state: paused;}a{color: #024794;}a:hover{text-decoration: none;}@keyframes text-shadow{0%{transform: translateY(0); text-shadow: 0 0 0 #0c2ffb, 0 0 0 #2cfcfd, 0 0 0 #fb203b, 0 0 0 #fefc4b;}20%{transform: translateY(-1em); text-shadow: 0 0.125em 0 #0c2ffb, 0 0.25em 0 #2cfcfd, 0 -0.125em 0 #fb203b, 0 -0.25em 0 #fefc4b;}40%{transform: translateY(0.5em); text-shadow: 0 -0.0625em 0 #0c2ffb, 0 -0.125em 0 #2cfcfd, 0 0.0625em 0 #fb203b, 0 0.125em 0 #fefc4b;}60%{transform: translateY(-0.25em); text-shadow: 0 0.03125em 0 #0c2ffb, 0 0.0625em 0 #2cfcfd, 0 -0.03125em 0 #fb203b, 0 -0.0625em 0 #fefc4b;}80%{transform: translateY(0); text-shadow: 0 0 0 #0c2ffb, 0 0 0 #2cfcfd, 0 0 0 #fb203b, 0 0 0 #fefc4b;}}@media (prefers-reduced-motion: reduce){*{animation: none !important; transition: none !important;}}</style><div id="wrapper"><div id="container"><h1>',
        "</h1></div></div></html>"
    ];

    string[8] hanginChad = [
        "<html><style>p{color: ",
        "; font-family: Avenir Next, Helvetica Neue, Helvetica, Tahoma, sans-serif; font-size: 1em; font-weight: 700;}p span{display: inline-block; position: relative; transform-style: preserve-3d; perspective: 500; -webkit-font-smoothing: antialiased;}p span::before,p span::after{display: none; position: absolute; top: 0; left: -1px; transform-origin: left top; transition: all ease-out 0.3s; content: attr(data-text);}p span::before{z-index: 1; color: ",
        "; transform: scale(1.1, 1) skew(0deg, 20deg);}p span::after{z-index: 2; color: ",
        "; text-shadow: -1px 0 1px ",
        ", 1px 0 1px ",
        "; transform: rotateY(-40deg);}p span:hover::before{transform: scale(1.1, 1) skew(0deg, 5deg);}p span:hover::after{transform: rotateY(-10deg);}p span + span{margin-left: 0.3em;}@media (min-width: 20em){p{font-size: 2em;}p span::before, p span::after{display: block;}}@media (min-width: 30em){p{font-size: 3em;}}@media (min-width: 40em){p{font-size: 5em;}}@media (min-width: 60em){p{font-size: 8em;}}html,body{margin: 0; padding: 0; height: 100%;}body{display: flex; align-items: center; justify-content: center; background-color: ",
        ";}</style><p>",
        "</p></html>"
    ];

    string[2] private shadowPop = [
        '<html><style>body{background:yellow;font-family: "Montserrat", sans-serif;}span{position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); font-size:120px;letter-spacing:0.1em; -webkit-text-fill-color: transparent; -webkit-text-stroke-width: 3px; -webkit-text-stroke-color: white; text-shadow: 8px 8px #ff1f8f,20px 20px #000000;}</style><span>',
        "</span></html>"
    ];

    string[] private splitVars;
    // string[2] private splitSite = [
    //     "<html><style>@import url('https://fonts.googleapis.com/css2?family=Poppins:ital,[email protected],900&display=swap'); body{",
    //     "padding:0;margin:0;font-family:'Poppins',sans-serif;background:var(--bC);height:100vh;width:100vw;}span{position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%); display: block; color: var(--sC); font-size: 124px; letter-spacing: 8px; cursor: pointer;}span::before{content: 'PRATHAM'; position: absolute; color: transparent; background-image: repeating-linear-gradient(45deg, transparent 0, transparent 2px, var(--sBC) 2px, var(--sBC) 4px); -webkit-background-clip: text; top: 0px; left: 0; z-index: -1; transition: 1s;}span::after{content: 'PRATHAM'; position: absolute; color: transparent; background-image: repeating-linear-gradient(135deg, transparent 0, transparent 2px, var(--sAC) 2px, var(--sAC) 4px); -webkit-background-clip: text; top: 0px; left: 0px; transition: 1s;}span:hover:before{top: 10px; left: 10px;}span:hover:after{top: -10px; left: -10px;}</style><span id=w></span></html>"
    // ];

    string[2] private splitSite = [
        "<html><style>@import url('https://fonts.googleapis.com/css2?family=Poppins:ital,[email protected],900&display=swap');body{text-transform: uppercase; --bC: ''; --sC: ''; --sBC: ''; --sAC: ''; --cB: ''; --cA: ''; --d1: ''; --d2: ''; padding: 0; margin: 0; font-family: 'Poppins', sans-serif; background: var(--bC); height: 100vh; width: 100vw;}span{position: absolute; left: 50%; top: 50%; transform: translate(-50%, -50%); display: block; color: var(--sC); font-size: 124px; letter-spacing: 8px; cursor: pointer;}span::before{content: var(--cB); position: absolute; color: transparent; background-image: repeating-linear-gradient(var(--d1), transparent 0, transparent 2px, var(--sBC) 2px, var(--sBC) 4px); -webkit-background-clip: text; top: 0px; left: 0; z-index: -1; transition: 1s;}span::after{content: var(--cA); position: absolute; color: transparent; background-image: repeating-linear-gradient(var(--d2), transparent 0, transparent 2px, var(--sAC) 2px, var(--sAC) 4px); -webkit-background-clip: text; top: 0px; left: 0px; transition: 1s;}span:hover:before{top: 10px; left: 10px;}span:hover:after{top: -10px; left: -10px;}</style><script></script><body onload=\"",
        "];document.querySelector('#w').textContent=w;st=document.body.style;for(let i=0;i<o.length;i++){ob=o[i];k=Object.keys(ob)[0];st.setProperty(k,ob[k]);}\"> <span id=w></span></html>"
    ];

    string[7] private website = [
        "<html><style>*{box-sizing: border-box;}html, body{height: 100%; width: 100%; overflow: hidden;}.container{width: 100%; height: 100%; position: relative; filter: contrast(",
        "); background-color:",
        "}h1{color:",
        "; font-size: ",
        "; text-transform: uppercase; white-space: nowrap; animation: letterspacing 10s infinite alternate cubic-bezier(1, 0.75, 0.5, 2.5); position: absolute; left: 50%; top: 35%; transform: translate3d(-50%, -50%, 0); -webkit-text-stroke: 0.5vw ",
        ';}@keyframes letterspacing{0%{letter-spacing: -2rem; filter: blur(18px);}100%{letter-spacing: 0.25rem; filter: blur(8px);}}</style><div class="container"> <h1>',
        "</h1></div></html>"
    ];

    string[4] private svg = [
        "<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 450 450' class='main'> <style> .main {background:",
        ";border:5px solid ",
        "}.Rrrrr{font:italic 40px serif; fill:",
        ";}</style></svg>"
    ];

    string[20] funnyWords = [
        "Erf",
        "Sozzled",
        "Smicker",
        "Salopettes",
        "Flabbergast",
        "Foppish",
        "Cattywampus",
        "Schmooze",
        "Finifugal",
        "Smaze",
        "Adorbs",
        "Widdershins",
        "Blubber",
        "Dollop",
        "Ramshackle",
        "Flummoxed",
        "Ill-willie",
        "Conjubilant",
        "Bunghole",
        "Geebung"
    ];

    string[35] nounLivingThings = [
        "Girl",
        "Boy",
        "Woman",
        "Man",
        "Child",
        "Animal",
        "Ape",
        "Cat",
        "Dog",
        "Insect",
        "Tiger",
        "Cheetah",
        "Spider",
        "Wolf",
        "Platypus",
        "Fish",
        "Whale",
        "Shark",
        "Dolphin",
        "Bear",
        "Panda",
        "Frog",
        "Amphibians",
        "Reptile",
        "Snake",
        "Hippo",
        "Dragon",
        "Unicorn",
        "Mermaid",
        "Werewolf",
        "Griffin",
        "Loch Ness Monster",
        "Goblin",
        "Alien",
        "Horse"
    ];

    string[34] nounNonlivingThings = [
        "Robot",
        "Computer",
        "Car",
        "Plane",
        "Color",
        "Explosion",
        "Ship",
        "Bus",
        "Train",
        "Boat",
        "Truck",
        "Motorcycle",
        "Bicycle",
        "Tractor",
        "Tricycle",
        "Building",
        "House",
        "Apartment",
        "Office",
        "School",
        "University",
        "Church",
        "Hospital",
        "Hotel",
        "Restaurant",
        "Bar",
        "Cafe",
        "Library",
        "Museum",
        "Theater",
        "Bridge",
        "Tunnel",
        "Tower",
        "Castle"
    ];

    string[26] adjectiveColors = [
        "Red",
        "Orange",
        "Yellow",
        "Green",
        "Blue",
        "Indigo",
        "Violet",
        "Black",
        "White",
        "Gray",
        "Brown",
        "Pink",
        "Purple",
        "Silver",
        "Gold",
        "Copper",
        "Bronze",
        "Brass",
        "Sky-blue",
        "Turquoise",
        "Emerald",
        "Sapphire",
        "Ruby",
        "Diamond",
        "Pearl",
        "Platinum"
    ];

    string[30] adjectiveDescriptions = [
        "Funny",
        "Cute",
        "Cool",
        "Beautiful",
        "Scary",
        "Silly",
        "Lame",
        "Ugly",
        "Stupid",
        "Smart",
        "Tired",
        "Hungry",
        "Sleepy",
        "Happy",
        "Sad",
        "Angry",
        "Lonely",
        "Lucky",
        "Famous",
        "Poor",
        "Wealthy",
        "Big",
        "Small",
        "Old",
        "New",
        "Fast",
        "Slow",
        "Strong",
        "Weak",
        "Courageous"
    ];

    string[7] adverbs = [
        "Quickly",
        "Slowly",
        "Carefully",
        "Bravely",
        "Slyly",
        "Cleverly",
        "Sneakily"
    ];

    string[22] verbs = [
        "Jump",
        "Run",
        "Walk",
        "Swim",
        "Fly",
        "Climb",
        "Sink",
        "Float",
        "Swing",
        "Shoot",
        "Hit",
        "Smash",
        "Bounce",
        "Brake",
        "Drive",
        "Sneak",
        "Hide",
        "Steal",
        "Sneak",
        "Steal",
        "Hide",
        "Sneak"
    ];

    string[15] shapes = [
        "Circle",
        "Square",
        "Triangle",
        "Rectangle",
        "Square",
        "Star",
        "Pentagon",
        "Hexagon",
        "Heptagon",
        "Octagon",
        "Nonagon",
        "Diamond",
        "Trapezoid",
        "Kite",
        "Crescent"
    ];

    string[28] artStyles = [
        "Stained glass",
        "Abstract",
        "Pixel-art",
        "Realistic",
        "Cartoon",
        "Fantasy",
        "Historical",
        "Political",
        "Watercolor",
        "Sketch",
        "Digital",
        "Traditional",
        "Modern",
        "Contemporary",
        "Minimalist",
        "Pop-art",
        "Surrealist",
        "Expressionist",
        "Oil painting",
        "8k Digital",
        "Figurative",
        "Geometric",
        "Nature",
        "Portraiture",
        "Still-life",
        "Vintage",
        "Typography",
        "Urban"
    ];

    string[26] famousArtist = [
        "Pablo Picasso",
        "Vincent van Gogh",
        "Andy Warhol",
        "Claude Monet",
        "Edvard Munch",
        "Edgar Degas",
        "Paul Cezanne",
        "Jackson Pollock",
        "Michelangelo",
        "Salvador Dali",
        "Salvatore Ferragamo",
        "Titian",
        "Umberto Boccioni",
        "Georgia O'Keeffe",
        "Frida Kahlo",
        "Mary Cassatt",
        "Leonora Carrington",
        "Elaine Sturtevant",
        "Helen Frankenthaler",
        "Kai Vermehr",
        "Steffen Sauerteig",
        "Svend Smital",
        "Mike Winkelmann",
        "Edgar Muller",
        "Kurt Wenner",
        "Julian Beever"
    ];

    string[10] wordNames = [
        "funnyWords",
        "nounLivingThings",
        "nounNonlivingThings",
        "adjectiveColors",
        "adjectiveDescriptions",
        "adverbs",
        "verbs",
        "shapes",
        "artStyles",
        "famousArtist"
    ];

    string[][10] wordlist;

    constructor() ERC721A("On chain AI NFT Game.", "AI_ART_GAME_WORDS") {
        wordlist[0] = funnyWords;
        wordlist[1] = nounLivingThings;
        wordlist[2] = nounNonlivingThings;
        wordlist[3] = adjectiveColors;
        wordlist[4] = adjectiveDescriptions;
        wordlist[5] = adverbs;
        wordlist[6] = verbs;
        wordlist[7] = shapes;
        wordlist[8] = artStyles;
        wordlist[9] = famousArtist;

        splitVars = [
            "'--bC':'",
            "'--sC':'",
            "'--sBC':'",
            "'--sAC':'",
            "'--cB':'\\'",
            "'--cA':'\\'",
            "'--d1':'",
            "'--d2':'"
        ];
        //Set all static variables on initialization.

        arcadeDudes[0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b]
            .royalities = 750;
        arcadeDudes[0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b]
            .canWithdraw = true;
        arcadeDudes[0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b].itemType = 1;

        arcadeDudes[address(this)].itemType = 1;

        arcadeOwner = msg.sender;
        _setDefaultRoyalty(0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b, 750);
        // userConfigList[0xC206277b9DC22D53A7D3d9DDb6441EF8923eEd23] = UserConfig(
        //     0,
        //     5,
        //     2,
        //     0xC206277b9DC22D53A7D3d9DDb6441EF8923eEd23,
        //     0xC206277b9DC22D53A7D3d9DDb6441EF8923eEd23,
        //     "apple"
        // );
    }

    modifier callerIsSender() {
        if (tx.origin != msg.sender) revert();
        _;
    }

    modifier callerIsNeo() {
        bool isTrue = arcadeDudes[msg.sender].itemType == 1 ||
            msg.sender == arcadeOwner;
        require(isTrue, "Only the Arcade owners can call this function.");
        _;
    }

    modifier mustBeOpen(uint256 amount) {
        // if (wordGeneration && balanceOf(msg.sender) == 0) _;
        //     userConfigList[msg.sender] = UserConfig(extraLives, false);
        require(wordGeneration, "Word generation is closed.");
        require(amount + _currentIndex <= 100000, "Word generation is done.");
        _;
    }

    modifier onlyValidAccess(
        uint256 _date,
        bytes memory _message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) {
        require(
            this.isValidAccessMessage(msg.sender, _date, _message, _v, _r, _s),
            "Invalid access message."
        );
        _;
    }

    function mirrorDisplayCreation(string memory word)
        private
        view
        returns (bytes memory)
    {
        bytes memory mirror = abi.encodePacked(mirrorDisplay[0]);

        for (uint256 i = 0; i < 234; i++) {
            if (i < 223)
                mirror = abi.encodePacked(mirror, '<div class="cell"></div>');
            if (i == 223) {
                mirror = abi.encodePacked(mirror, '<div class="content">');
            }
            if (i > 223) {
                mirror = abi.encodePacked(
                    mirror,
                    '<div class="css">',
                    word,
                    "</div>"
                );
            } else if (i == 233) {
                mirror = abi.encodePacked(mirror, "</div></html>");
            }
        }
        return mirror;
    }

    //w='test';o=[{'--bC':'pink'},{'--sC':'blue'},{'--sBC':'green'},{'--sAC':'purple'},{'--d1':'61deg'},{'--d2':'151deg'},{'--cA':''test''},{'--cB':''test''}]
    function loopCssVarColors(uint256 tokenId, string[] memory vars)
        private
        view
        returns (bytes memory)
    {
        bytes memory newJs;
        for (uint256 i = 0; i < vars.length; i++) {
            uint256 _seed = generateSeed(tokenId + 69 + i);
            newJs = abi.encodePacked(
                newJs,
                "{",
                vars[i],
                rgba(
                    generateNumber((_seed + 69), 255),
                    generateNumber((_seed + 420), 255),
                    generateNumber((_seed + 123), 255),
                    1
                ),
                "'},"
            );
        }
        return newJs;
    }

    function loopCssSplit(
        uint256 tokenId,
        string[2] memory vars,
        string memory strings
    ) private view returns (bytes memory) {
        bytes memory newCss;
        for (uint256 i = 0; i < vars.length; i++) {
            string[] memory letters = stringToArray(strings);
            string memory str;

            for (uint256 j = 0; j < letters.length; j++) {
                uint256 _seed = generateSeed(tokenId + 69 + j);
                uint256 random = generateNumber((_seed), 4);
                str = string(abi.encodePacked(str, letters[j]));
                if (random == 1) str = string(abi.encodePacked(str, "_"));
            }

            newCss = abi.encodePacked(newCss, "{", vars[i], str, "\\''},");
        }
        return newCss;
    }

    function loopCssNumbers(
        uint256 tokenId,
        string memory addOnCss,
        uint16[2] memory min_max,
        string[] memory vars
    ) public view returns (bytes memory) {
        bytes memory newCss;
        for (uint256 i = 0; i < vars.length; i++) {
            uint256 _seed = generateSeed(tokenId + i);
            string memory str = Strings.toString(
                generateNumber(_seed, min_max[1]) + min_max[0]
            );
            newCss = abi.encodePacked(
                newCss,
                "{",
                vars[i],
                str,
                addOnCss,
                "'},"
            );
        }
        return newCss;
    }

    function splitContentFunction() private {}

    function stringToArray(string memory str)
        private
        pure
        returns (string[] memory)
    {
        bytes memory b = bytes(str);
        string[] memory words = new string[](b.length);
        for (uint256 index = 0; index < b.length; index++) {
            words[index] = string(abi.encodePacked(b[index]));
        }

        return words;
    }

    // function stringToArray(string memory word)
    //     private
    //     pure
    //     returns (string[] memory)
    // {
    //     strings.slice memory s = word.toSlice()

    //     strings.slice memory part;
    //     string[] memory words = new string[](strLength(word));
    //     for (uint256 i = 0; i < strLength(word); i++) {
    //         words[i] = s.split(word.toSlice(), part).toString();
    //     }

    //     return words;
    // }

    function rgba(
        uint256 r,
        uint256 g,
        uint256 b,
        uint256 a
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                "rgba(",
                Strings.toString(r),
                ",",
                Strings.toString(g),
                ",",
                Strings.toString(b),
                ",",
                Strings.toString(a),
                ")"
            );
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from)
            revert TransferFromIncorrectOwner();

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (
            !_isSenderApprovedOrOwner(
                approvedAddress,
                from,
                _msgSenderERC721A()
            )
        )
            if (!isApprovedForAll(from, _msgSenderERC721A()))
                revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED |
                    _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }
        tokenInfo[tokenId].date = 0;
        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721A, ERC2981)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function burnToken(uint256 tokenId) public callerIsNeo {
        _burn(tokenId);
    }

    function isValidAccessMessage(
        address _address,
        uint256 date,
        bytes calldata message,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external view returns (bool) {
        bytes32 hash = keccak256(
            abi.encodePacked(address(this), _address, date, message)
        );
        require(date > block.timestamp, "Request has expired.");
        address sender = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ),
            _v,
            _r,
            _s
        );

        bool Neo = arcadeDudes[sender].itemType == 1 || sender == arcadeOwner;
        return Neo;
    }

    function amINeo() public view returns (bool) {
        return
            arcadeDudes[msg.sender].itemType == 1 || msg.sender == arcadeOwner;
    }

    function enableWordGenerationAndReveal(uint8 toggle) public callerIsNeo {
        if (toggle == 0) wordGeneration = true;
        else if (toggle == 1) unhideWord = true;
        else revert();
    }

    function generateSeed(uint256 tokenId) private view returns (uint256) {
        uint256 _seed = uint256(keccak256(abi.encodePacked(seed, tokenId)));
        return _seed;
    }

    function generateNumber(uint256 _seed, uint256 number)
        private
        pure
        returns (uint256)
    {
        return _seed % number;
    }

    function battleArena(uint256[6] memory gladiators, uint256 _seed)
        private
        view
        returns (uint256[6] memory)
    {
        uint256 randomSeed = generateSeed(_seed);
        uint256 randomNumber = generateNumber(randomSeed, 5);
        if (gladiators[randomNumber] == 0) {
            gladiators[5] += 1;
            gladiators[randomNumber] = gladiators[5];
        }
        if (gladiators[5] == 5) return gladiators;
        else return battleArena(gladiators, randomSeed);
    }

    function grabMyGladiatorPlace(uint256 tokenId)
        private
        view
        returns (uint256)
    {
        uint256[6] memory gladiators = battleArena(
            [uint256(0), 0, 0, 0, 0, 0],
            generateSeed(tokenId - generateNumber(tokenId, 5))
        );

        for (uint256 i = 0; i < 5; i++) {
            if (
                generateNumber(gladiators[i], 2) == 1 &&
                generateNumber(generateSeed(tokenId), 2) == 1
            ) {
                uint8[3] memory newIndex = [6, 7, 8];
                gladiators[i] = newIndex[
                    generateNumber(generateSeed(tokenId), 3)
                ];
            }
            if (gladiators[i] == 2) {
                uint256 superRare = generateNumber(generateSeed(tokenId), 30);
                if (superRare == 0) {
                    gladiators[i] = 9;
                }
                if (superRare == 1) {
                    gladiators[i] = 10;
                }
            }
        }

        return gladiators[generateNumber(tokenId, 5)];
    }

    function grabWord(uint256 tokenId) public view returns (string memory) {
        uint256 wordIndex = grabMyGladiatorPlace(tokenId);
        return
            wordlist[wordIndex - 1][
                generateNumber(
                    generateSeed(tokenId),
                    wordlist[wordIndex - 1].length
                )
            ];
    }

    function wordType(uint256 tokenId) private view returns (string memory) {
        uint256 wordIndex = grabMyGladiatorPlace(tokenId);
        return wordNames[wordIndex - 1];
    }

    function adminMint(address _to, uint256 _quantity) public callerIsNeo {
        _safeMint(_to, _quantity);
    }

    function generateWords(VerifiedMessage calldata vm)
        external
        payable
        callerIsSender
        nonReentrant
        mustBeOpen(vm.message[0])
        onlyValidAccess(
            vm.message[3],
            abi.encodePacked(vm.message[0], vm.message[1], vm.message[2]),
            vm.signature._v,
            vm.signature._r,
            vm.signature._s
        )
    {
        if (vm.message[2] > 0) {
            //generate the tokens here
            require(
                maxMint[msg.sender] == 0,
                "Hey one claim of tokens. Don't be greedy."
            );
            token.mint(msg.sender, vm.message[2] * 1 ether);
        }
        if (maxMint[msg.sender] == 0) {
            maxMint[msg.sender] = vm.message[1] + 1;
        }
        require(vm.message[0] < maxMint[msg.sender], "Over mint amount.");
        maxMint[msg.sender] -= vm.message[0];

        _safeMint(msg.sender, vm.message[0]);
    }

    function setArcadeDude(
        address dudesAddress,
        uint256 dudesType,
        uint256 royalties,
        uint256 withdrawAmmount,
        bool monthlyReset,
        bool canWithdraw
    ) external callerIsNeo {
        arcadeDudes[dudesAddress] = MaintenanceDudes(
            dudesType,
            canWithdraw,
            monthlyReset,
            block.timestamp,
            withdrawAmmount,
            royalties
        );
    }

    function setNEURAToken(address _address) public callerIsNeo {
        token = NEURAL(_address);
    }

    function createHanginChad(string[] memory words)
        private
        pure
        returns (bytes memory)
    {
        bytes memory chadBytes;
        for (uint256 i = 0; i < words.length; i++) {
            chadBytes = abi.encodePacked(
                chadBytes,
                '<span data-text="',
                words[i],
                '">',
                words[i],
                "</span>"
            );
        }
        return chadBytes;
    }

    function buildSplit(string memory word, uint256 tokenId)
        private
        view
        returns (bytes memory)
    {
        bytes memory animationBytes;
        string[] memory colors = new string[](4);
        string[2] memory others;
        for (uint256 i = 0; i < splitVars.length; i++) {
            if (i < 4) {
                colors[i] = splitVars[i];
            } else if (i > 3 && i < 6) {
                others[i - 4] = splitVars[i];
            }
        }
        string[] memory varsOne = new string[](1);
        varsOne[0] = splitVars[6];
        string[] memory varsTwo = new string[](1);
        varsTwo[0] = splitVars[7];
        animationBytes = abi.encodePacked(
            splitSite[0],
            "w='",
            word,
            "';o=[",
            loopCssVarColors(tokenId, colors),
            loopCssSplit(tokenId, others, word),
            loopCssNumbers(tokenId, "deg", [0, 360], varsOne),
            loopCssNumbers(tokenId, "deg", [90, 360], varsTwo),
            splitSite[1]
        );
        return animationBytes;
    }

    function animationCreator(
        string memory word,
        uint256 tokenId,
        uint256 _seed,
        uint256 animationType
    ) private view returns (string memory) {
        string memory base64;

        //string(mirrorDisplayCreation(word)

        string[6] memory vars = [
            Strings.toString((_seed % 3) + 1),
            string(
                rgba(
                    generateNumber(_seed + 69, 255),
                    generateNumber(_seed + 420, 255),
                    generateNumber(_seed + 123, 255),
                    1
                )
            ),
            string(
                rgba(
                    generateNumber(_seed + 96, 255),
                    generateNumber(_seed + 1337, 255),
                    generateNumber(_seed + 7331, 255),
                    1
                )
            ),
            strLength(word) < 8 ? "20vw" : strLength(word) < 14
                ? "10vw"
                : "8vw",
            string(
                rgba(
                    generateNumber(_seed + 666, 255),
                    generateNumber(_seed + 999, 255),
                    generateNumber(_seed, 255),
                    1
                )
            ),
            word
        ];
        bytes memory animationBytes;

        // for (uint256 index = 0; index < 7; index++) {}
        if (animationType == 0) {
            for (uint256 i = 0; i < vars.length; i++) {
                animationBytes = abi.encodePacked(
                    animationBytes,
                    website[i],
                    vars[i]
                );
            }
            animationBytes = abi.encodePacked(animationBytes, website[6]);
        } else if (animationType == 2) {
            animationBytes = buildSplit(word, tokenId);
        } else if (animationType == 3) {
            for (uint256 i = 0; i < 1; i++) {
                animationBytes = abi.encodePacked(
                    animationBytes,
                    fatStripe[i],
                    word
                );
            }
            animationBytes = abi.encodePacked(animationBytes, fatStripe[1]);
        } else if (animationType == 4) {
            for (uint256 i = 0; i < 1; i++) {
                animationBytes = abi.encodePacked(
                    animationBytes,
                    jumpSplit[i],
                    word
                );
            }
            animationBytes = abi.encodePacked(animationBytes, jumpSplit[1]);
        } else if (animationType == 5) {
            string[] memory chads = stringToArray(word);
            for (uint256 i = 0; i < 1; i++) {
                animationBytes = abi.encodePacked(
                    animationBytes,
                    hanginChad[i],
                    createHanginChad(chads)
                );
            }
            animationBytes = abi.encodePacked(animationBytes, hanginChad[1]);
        } else {
            for (uint256 i = 0; i < 1; i++) {
                animationBytes = abi.encodePacked(
                    animationBytes,
                    shadowPop[i],
                    word
                );
            }
            animationBytes = abi.encodePacked(animationBytes, shadowPop[1]);
        }
        if (animationType == 1) {
            base64 = Base64.encode(mirrorDisplayCreation(word));
        } else base64 = Base64.encode(animationBytes);
        return string(abi.encodePacked("data:text/html;base64,", base64));
    }

    function svgCreator(bytes[3] memory vars)
        private
        view
        returns (bytes memory)
    {
        bytes memory svgBytes;
        for (uint256 i = 0; i < vars.length; i++) {
            svgBytes = abi.encodePacked(svgBytes, svg[i], vars[i]);
        }

        return abi.encodePacked(svgBytes, svg[3]);
    }

    function tokenAttributes(uint256 tokenId)
        public
        view
        returns (uint256[5] memory)
    {
        uint256 tokenYield = generateNumber(generateSeed(tokenId), 10) + 1;
        uint256 reWord = generateNumber(generateSeed(tokenId), 5) + 1;
        uint256 yoinks = generateNumber(generateSeed(tokenId + 420), 5) + 1;
        bool freePhrase = generateNumber(tokenId, 1337) == 420 ||
            generateNumber(tokenId, 1337) == 69;
        bool freeProtection = generateNumber(tokenId, 500) == 420 ||
            generateNumber(tokenId, 1337) == 69;
        return [
            tokenYield,
            reWord,
            yoinks,
            freePhrase ? 1 : 0,
            freeProtection ? 1 : 0
        ];
    }

    function strLength(string memory s) private pure returns (uint256) {
        return bytes(s).length;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        bytes memory metaBytes;
        Attributes[10] memory attributes;
        AttributesNumbers[3] memory attributesNumbers;
        uint8[2] memory count;
        uint256 _seed = generateSeed(tokenId);
        string memory word = grabWord(tokenId);
        uint256 animationType = generateNumber(_seed, 7);
        string memory animation = animationCreator(
            word,
            tokenId,
            _seed,
            animationType
        );

        string[4] memory metadataVars = [
            string(unhideWord ? word : "Waiting on reveal..."),
            unhideWord
                ? animation
                : "https://i.pinimg.com/originals/eb/bd/f7/ebbdf7ce4f7f502d1f28b96b5cbd7a1f.gif",
            Strings.toString(tokenId),
            string(
                svgCreator(
                    [
                        rgba(
                            generateNumber(_seed + 69, 255),
                            generateNumber(_seed + 420, 255),
                            generateNumber(_seed + 123, 255),
                            1
                        ),
                        rgba(
                            generateNumber(_seed + 96, 255),
                            generateNumber(_seed + 1337, 255),
                            generateNumber(_seed + 7331, 255),
                            1
                        ),
                        rgba(
                            generateNumber(_seed + 666, 255),
                            generateNumber(_seed + 999, 255),
                            generateNumber(_seed, 255),
                            1
                        )
                    ]
                )
            )
        ];

        bool freePhrase = generateNumber(_seed, 1337) == 420 ||
            generateNumber(_seed, 1337) == 69;
        bool freeProtection = generateNumber(_seed, 500) == 420 ||
            generateNumber(_seed, 1337) == 69;
        attributes[0] = Attributes("Word", grabWord(tokenId));
        attributes[1] = Attributes("Word Type", wordType(tokenId));
        attributes[2] = Attributes("Word Style", wordStyle[animationType]);
        count[0] = 3;
        if (freePhrase) {
            count[0]++;
            attributes[4] = Attributes("Phrase Upgrade", "Yes");
        }
        if (freeProtection) {
            count[0]++;
            attributes[3] = Attributes("Protected", "Yes");
        }
        attributesNumbers[0] = AttributesNumbers(
            "Daily Token Yield",
            "",
            generateNumber(_seed, 10) + 1,
            10
        );
        attributesNumbers[1] = AttributesNumbers(
            "Re-Word",
            "",
            generateNumber(_seed, 5) + 1,
            5
        );
        attributesNumbers[2] = AttributesNumbers(
            "Yoinks",
            "",
            generateNumber(_seed + 11, 5) + 1,
            5
        );
        count[1] = 3;

        for (uint8 i = 0; i < metadataVars.length; i++) {
            metaBytes = abi.encodePacked(
                metaBytes,
                metadata[i],
                metadataVars[i]
            );
        }

        bytes memory fullBytes = abi.encodePacked(
            metaBytes,
            unhideWord
                ? attributeCreator(attributes, attributesNumbers, count)
                : bytes('"'),
            metadata[4]
        );

        string memory json = Base64.encode(fullBytes);
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function stakeToken(uint256 tokenId) internal {
        tokenInfo[tokenId].date = block.timestamp;
    }

    function attributeCreator(
        Attributes[10] memory attributes,
        AttributesNumbers[3] memory attributeNumbers,
        uint8[2] memory sizes
    ) private view returns (bytes memory) {
        bytes memory attributeBytes;
        bytes memory numberAttributeBytes;
        if (!unhideWord) return attributeBytes;
        for (uint8 i = 0; i < sizes[1]; i++) {
            numberAttributeBytes = abi.encodePacked(
                numberAttributeBytes,
                '{"trait_type":"',
                string(attributeNumbers[i].trait_type),
                '","display_type":"',
                string(attributeNumbers[i].display_type),
                '","value":',
                Strings.toString(attributeNumbers[i].value),
                ',"max_value":',
                Strings.toString(attributeNumbers[i].max),
                "},"
            );
        }

        for (uint8 i = 0; i < sizes[0]; i++) {
            // if (keccak256(abi.encode(attributes[i].value)) != "") {
            bytes memory attribute = abi.encodePacked(
                attributeBytes,
                '{"trait_type":"',
                attributes[i].trait_type,
                '","value":"',
                attributes[i].value,
                i == sizes[0] - 1 ? '"}]' : '"},'
            );
            attributeBytes = i == 0
                ? abi.encodePacked(
                    '","attributes":[',
                    attribute,
                    numberAttributeBytes
                )
                : abi.encodePacked(attribute);
            // }
        }
        return attributeBytes;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "./IERC721A.sol";

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 internal constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 internal constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 internal constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 internal constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 internal constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) public _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) internal _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return
            (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return
            (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) &
            _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed =
            (packed & _BITMASK_AUX_COMPLEMENT) |
            (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length != 0
                ? string(abi.encodePacked(baseURI, _toString(tokenId)))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId)
        internal
        view
        virtual
        returns (TokenOwnership memory)
    {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index)
        internal
        view
        virtual
        returns (TokenOwnership memory)
    {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed)
        private
        pure
        returns (TokenOwnership memory ownership)
    {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags)
        internal
        view
        returns (uint256 result)
    {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(
                owner,
                or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags)
            )
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity)
        internal
        pure
        returns (uint256 result)
    {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) internal pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        internal
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from)
            revert TransferFromIncorrectOwner();

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (
            !_isSenderApprovedOrOwner(
                approvedAddress,
                from,
                _msgSenderERC721A()
            )
        )
            if (!isApprovedForAll(from, _msgSenderERC721A()))
                revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED |
                    _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        try
            ERC721A__IERC721Receiver(to).onERC721Received(
                _msgSenderERC721A(),
                from,
                tokenId,
                _data
            )
        returns (bytes4 retval) {
            return
                retval ==
                ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)

                    //        tokenInfo[tokenId].date = block.timestamp;
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT)
            revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] +=
                quantity *
                ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) |
                    _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(
                startTokenId,
                startTokenId + quantity - 1,
                address(0),
                to
            );

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (
                        !_checkContractOnERC721Received(
                            address(0),
                            to,
                            index++,
                            _data
                        )
                    ) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, "");
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (
            uint256 approvedAddressSlot,
            address approvedAddress
        ) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (
                !_isSenderApprovedOrOwner(
                    approvedAddress,
                    from,
                    _msgSenderERC721A()
                )
            )
                if (!isApprovedForAll(from, _msgSenderERC721A()))
                    revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) |
                    _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed =
            (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) |
            (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) internal view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value)
        internal
        pure
        virtual
        returns (string memory ptr)
    {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../TheAIArtGame.sol";

contract NEURAL is ERC20, Ownable, ReentrancyGuard {
    TheAIArtGame ai;

    address testControllerAddy;

    uint256 public rewardStartDate = block.timestamp;

    struct TokenInfo {
        uint256 claimDate;
        uint8[4] attributes;
    }

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) public controllers;
    mapping(uint256 => TokenInfo) tokenInfo;

    constructor(address _aiAddress) ERC20("NEURAL", "NEURAL") {
        controllers[msg.sender] = true;
        controllers[_aiAddress] = true;
        ai = TheAIArtGame(_aiAddress);
    }

    modifier callerIsSender() {
        if (tx.origin != msg.sender) revert();
        _;
    }

    /**
     * mints $QTER to a recipient
     * @param to the recipient of the $QTER
     * @param amount the amount of $QTER to mint
     */

    function mint(address to, uint256 amount) public {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    }

    function testController() public {
        testControllerAddy = msg.sender;
    }

    /**
     * burns $QTER from a holder
     * @param from the holder of the $QTER
     * @param amount the amount of $QTER to burn
     */
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    }

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function setAIGame(address _address) public onlyOwner {
        ai = TheAIArtGame(_address);
    }

    // function getStakedTimed(uint256 tokenId) public view returns (uint256) {
    //     return ai.getStakedTime(tokenId);
    // }

    function abs(int256 x) private pure returns (int256) {
        return x >= 0 ? x : -x;
    }

    function getTotalTime(uint256 _tokenId) public view returns (uint256) {
        if (tokenInfo[_tokenId].claimDate == 0) {
            return block.timestamp - rewardStartDate;
        }
        return block.timestamp - tokenInfo[_tokenId].claimDate;
    }

    function getRewardAmount(uint256 tokenId) public view returns (uint256) {
        uint256[5] memory attributes = ai.tokenAttributes(tokenId);
        uint256 tokenYield = attributes[0]; //multiplier for x1 token per day
        uint256 tokenTime = getTotalTime(tokenId) * 1 ether; //current date minus reward claim date
        tokenTime = tokenTime / 86400;
        tokenTime = tokenTime * tokenYield;
        //convert to ether
        uint256 amount = tokenTime;
        return amount;
    }

    function getRewardAmountNoEth(uint256 tokenId)
        public
        view
        returns (uint256)
    {
        uint256[5] memory attributes = ai.tokenAttributes(tokenId);
        uint256 tokenYield = attributes[0]; //multiplier for x1 token per day
        uint256 tokenTime = getTotalTime(tokenId); //current date minus reward claim date
        tokenTime = tokenTime * tokenYield;
        //convert to ether
        uint256 amount = tokenTime;
        return amount;
    }

    function claimReward(uint256 tokenId) public {
        tokenOwnerOf(tokenId);
        uint256 rewardAmount = getRewardAmount(tokenId);
        tokenInfo[tokenId].claimDate = block.timestamp;
        _mint(msg.sender, rewardAmount);
    }

    function claimRewardNoEth(uint256 tokenId) public {
        tokenOwnerOf(tokenId);
        uint256 rewardAmount = getRewardAmountNoEth(tokenId);
        tokenInfo[tokenId].claimDate = block.timestamp;
        _mint(msg.sender, rewardAmount);
    }

    function tokenOwner(uint256 tokenId) public view returns (address) {
        return ai.ownerOf(tokenId);
    }

    function tokenOwnerOf(uint256 tokenId) private view {
        bool isOwner = ai.ownerOf(tokenId) == msg.sender;
        require(isOwner, "You do not own this token");
    }

    function checkBalance(address _sender) public view returns (uint256) {
        uint256 balance = balanceOf(_sender);
        require(
            balance >= 1 * 1 ether,
            "You don't have enough QTER to change the layout"
        );

        return balance;
    }

    // function claimSnakeQTER(uint256 tokenId) public returns (uint256) {
    //     snakeTokenOwnerOf(tokenId);
    //     SnakeTokenInfo memory info = getSnakeStakeTime(tokenId);
    //     //get total time staked to increase the reward
    //     uint256 totalTimeStaked = (block.timestamp - info.stakeDate) / 86400;
    //     //get the reward amount based on last stake time;
    //     uint256 totalStakedSinceLastClaim = (block.timestamp - info.lastClaim) *
    //         5;
    //     //reward add multiplayer for every month staked since last claim
    //     uint256 rewardTotalMultiplayer = totalTimeStaked / (60 * 60 * 24);

    //     //reward add multiplier for every minute staked since last claim
    //     uint256 rewardTotal = (
    //         ((totalStakedSinceLastClaim * rewardTotalMultiplayer) / 60)
    //     ) * 1 ether;
    //     ai.setClaimTime(tokenId);
    //     _mint(msg.sender, rewardTotal);
    //     return rewardTotal;
    // }

    // function getTotalSnakeQTER(uint256 tokenId) public view returns (uint256) {
    //     SnakeTokenInfo memory info = getSnakeStakeTime(tokenId);
    //     //get total time staked to increase the reward
    //     uint256 totalTimeStaked = (block.timestamp - info.stakeDate) * 10;
    //     //get the reward amount based on last stake time;
    //     uint256 totalStakedSinceLastClaim = (block.timestamp - info.lastClaim) *
    //         10;
    //     //reward add multiplayer for every day staked since last claim
    //     uint256 rewardTotalMultiplayer = totalTimeStaked / (60 * 60 * 24);

    //     //reward add multiplier for every minute staked since last claim
    //     uint256 rewardTotal = (
    //         ((totalStakedSinceLastClaim + rewardTotalMultiplayer) / 60)
    //     ) * 1 ether;

    //     return rewardTotal;
    // }

    // function stakeSnakeTokensCount(uint256[] memory tokenIds, uint256 count)
    //     public
    // {
    //     //        uint256 stakeDate = ai.getStakeArray(tokenId)[0];

    //     ai.stakeTokens(count, msg.sender, tokenIds);
    //     // ai.tokenInfoList(tokenId).stakeDate = block.timestamp;
    // }

    // function stakeSnakeTokens(uint256[] memory tokenIds) public {
    //     //        uint256 stakeDate = ai.getStakeArray(tokenId)[0];

    //     for (uint256 index = 0; index < tokenIds.length; index++) {
    //         snakeTokenOwnerOf(tokenIds[index]);
    //         //ai.stakeToken(tokenIds[index]);
    //     }
    //     ai.stakeToken(tokenIds[0]);
    //     // ai.tokenInfoList(tokenId).stakeDate = block.timestamp;
    // }

    function amINeo() public view returns (bool) {
        return ai.amINeo();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed from,
        address indexed to
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}