//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "./ERC721G.sol";
import "./AiAlbumFamiliar.sol";

//species, eyes, nose, mouth, background, accessories, accesoriesCount, first Name, last Name, sex,

contract AiAlbumMint is ERC721G, Ownable, ReentrancyGuard {
    AiAlbumFamiliar private familiarContract;

    address private NEO;
    bytes public baseURI = "https://oca.mypinata.cloud/ipfs/";

    address private The_Dude = 0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b;

    uint8 bgTypeCount = 2;
    uint8 eyesCount = 1;
    uint8 eyeColorCount = 10;
    uint8 gradientColorCount = 22;
    uint8 speciesCount = 4;
    uint8 speciesColorCount = 5;
    uint256 lastTokenId;

    string bgViewBox = "0 0 1280 1280";

    //     bgSvg[0],
    // c1,
    // bgSvg[1],
    // c2,
    // bgSvg[2],
    // generateHead(),
    // bgSvg[3]

    string[2] private bgSvg = [
        "<svg id='villager' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' overflow='visible'  shape-rendering='geometricPrecision' text-rendering='geometricPrecision' viewBox='",
        "'><style>@font-face{font-family:Mafia;src:url(data:application/font-ttf;base64,AAEAAAAOAIAAAwBgRkZUTZ1455YAABM8AAAAHEdERUYAFQAUAAATIAAAABxPUy8yVjJheQAAAWgAAABgY21hcD77ZaQAAAIgAAABWmN2dCAAIgKIAAADfAAAAARnYXNw//8AAwAAExgAAAAIZ2x5ZgTjIrwAAAO4AAANHGhlYWQhkT5PAAAA7AAAADZoaGVhBuQDpwAAASQAAAAkaG10eCzT/nsAAAHIAAAAWGxvY2E7jD6MAAADgAAAADhtYXhwAGEA9AAAAUgAAAAgbmFtZQ4KvAYAABDUAAAB6XBvc3QBHwGdAAASwAAAAFgAAQAAAAEAAJzxhbtfDzz1AAsEAAAAAADflduAAAAAAN+WHt3/3/+2A2cDPwAAAAgAAgAAAAAAAAABAAADP/+2AFwEAP/f/98DZwABAAAAAAAAAAAAAAAAAAAAEQABAAAAGwDDAAQAAAAAAAIAAAABAAEAAABAAC4AAAAAAAQDagGQAAUAAAKZAswAAACPApkCzAAAAesAMwEJAAACAAUDAAAAAAAAAAAAAQAAAAAAAAAAAAAAAFBmRWQAgAAjAEkDM/8zAFwDPwBKAAAAAQAAAAAAAAAAAAAAIAABAXYAIgAAAAABVQAAA0b/3wIu/+ACLv/gAzP/4AEw/98DRv/fAzP/4AMz/+ADM//gA0b/3wNG/98DRv/fA0b/3wQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAMAAAADAAAAHAABAAAAAABUAAMAAQAAABwABAA4AAAACgAIAAIAAgAjACkAOQBJ//8AAAAjACgAMAA/////4P/c/9b/0QABAAAAAAAAAAAAAAAAAQYAAAEAAAAAAAAAAQIAAAACAAAAAAAAAAAAAAAAAAAAAQAAAAAAAwAAAAAEBQAAAAAAAAYHCAkKCwwNDg8AAAAAABAREhMUFRYXGBkaAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAiAogAAAAqACoAKgE0AZQB6gJYAqYDTgPGBD4E5AVGBaAGJgaOBo4GjgaOBo4GjgaOBo4GjgaOBo4GjgACACIAAAEyAqoAAwAHAC6xAQAvPLIHBADtMrEGBdw8sgMCAO0yALEDAC88sgUEAO0ysgcGAfw8sgECAO0yMxEhESczESMiARDuzMwCqv1WIgJmAAAD/9//tgNnAz8AAwBsAMIAAAEjFTMFFA4CKwEVFA4CIyInLgI9ASMVFAcOAiMiLgI9ASMiJjU0Njc2NzY7ATUjIiYnLgE1NDc2Nz4BOwE1ND4CMzIeARcWHQEzNTQ+ATc2MzIWHQEzMh4CFRQGKwEVMzIXHgEXFhc0JyYnNzY1NCcmJy4BJyYnJiMiBwYHJicmIyIHBgcOAQcGBwYHBgcGFRQXFhcGBwYVFBcWFxYXFhcWFx4BMzI3NjcWFxYzMjc2NzY3Njc2NzY3Njc2AbksLAFlEh4qFhYSHigXGRMUHhIsCAkeKhYYKB4SFi1CEg4PFBEbFhYYKA8OEgkKDQ8oGBYSHigYFioeCQgsEh4UExktQhYWKh4SQi4WFhgTFR4JCUkPDxsDNgoJFRI0HQwlNkwnIyMZGSMjJiMbHhgWJAcdGhsREwoKDw8bGw8PNxMUExkHEhIWGDwgJCUjGRkjJSUgHhwZFhIPCB8ZGhIVCQoBkS1uGCgeEhYYKB4SCQkeKBgWFhsRFB4SEh4oGBZCLhYqDg8JCC0SDw4oGBYVFw0PEhYWKh4SEh4VExgWFhYqHgkJQi4WEh4qFi1CLQgJHhQTGCgiIxgDNkwiGxobGCIHMSU2Dw8bGw8PCgsSETYeBxESFhkcGyMoIiMYGSMjJkw3Ew0MBRwcGxESFhAPGxsPEAsKExEbFyEIEBEYGxobAAAAAv/g/7gCTgMsACIARQAAJRQOAiMiJjU0NzYzMh4CFRQOAiMiBwYVFBcWMzIeAhc0LgIjIicmNTQ3NjMyPgI1NC4CIyIHBhUUADMyPgICBhEeKBaZ2GxtmBYoHhERHigWPy0sLC4+FigeEUgcMkIlIhYYFxghJUIyHBwyQiW2goEBArclQjIcbRcnHhHYmplsbREeKBYXJx4RLSw/Pi4sER4oFiVCMhwWGCIhFxgcMkEmJUIyHIKBt7j+/hwyQQAAAv/g/7gCTgMsAB4APQAAARQHBiMiJjU0PgIzMjc2NTQmIyImNTQ+AjMyFxYXNCcmIyIOAhUUFjMyFhUUBwYjIg4CFRQWMzI3NgIGbWyZLEARHScXPi4tWj8sQBEdJxeZbG1IgoG3JkIwHGpKITAXGCImQjAcakq3gYIBcpltbEAtFigeESwrQT5aQC0WKB4RbWyZt4GCHDJCJUtqMCAhFxgcMkIlS2qBggAAAAP/4P+4A1MDLAApAEAATgAAJRQOAiMiJjURNCYjIgcGFRQXFjMyHgIVFA4CIyImNTQ3NjMyFxYVMzQnJiMiBwYVFAAzMjY3FxYzMj4CNSUiJyY1NDc2MzIWHQEmAwsRHigWLEBaPz8tLCwuPhYoHhERHigWmdhsbZiZbG1IgoG3toKBAQK3JkQZAzVKJUIyHP5GIhYYFxghITAobRcnHhFALQEFPlotLD8+LiwRHigWFyceEdiamWxtbWyZt4GCgoG3uP7+HhoDNRwyQSa1FhgiIRcYMCBjEwAAAAAC/9//tgFRAz8AGQAyAAAlFAYHBgcGIyImNRE0NzY3PgEzMhcWFx4BFTM0Jy4BJyYjIgcOAQcGFREUFjMyPgE3NjUBBxIPEBMVFi1CCQoNDygYFhUTEA8SSg4PMiMgJykgJC4PD25LJEYyDw5wGCgPEAgJQi4CFhYVFw0PEgkIEA8qFiggIjIPDg4QMCMiJv3qTG4eMiEfKgAAAAAD/9//tgNnAz8AFwBEAHQAACUUDgIjISImNTQ2NzY3NjMhMhYXFhcWBRQHBgcOASMiJjU0NjsBJicmIyEiJyY1NDc2Nz4BMyEyFhUUBw4CIyEiBwYFNCcmJzY3NjU0JyYjISIHDgEHBhUUFxYXBw4BBwYVFBYzMjc2NxcWMyEyNz4BNzYDHhIeKhb+9S1CEg4QExEbAQsYJhEQCAn96QkKDQ4qFy1C3pxtFxobIf71LiAhCQoNDygYAQub4AkJHioW/vVBLi0CYA8PGxsPD4WEu/71KSAkLg8PNy5AEAIMA4RuSyUlIhoDN0sBCyYiIjIPDnAYKB4SQi4WKg4QCQgQERATFRYXFRcNDhJCLpzeFQwMICEuFhUXDQ8S4JsZExQeEi4tQCYjIxkZIyMnu4SFDhAwIyImTDcvBhACCgOEu0xuEA8bAzcPDzIhHwAAAAAC/+D/uANTAywAMABXAAABFAcGIyEiJjU0PgIzITI2NwYjIiY1ND4CMzI3ISImNTQ+AjMhMh4CFRQGBxYXNCYnPgE1NC4CIyEiDgIVFBY7AQYVFBcjIg4CFRQWMyEyNzYDC21smf77LEARHScXAQUmQhU9QCxAER0nFz8s/pAsQBEdJxcCChYoHhEWFixIEA4PDxwyQiX99iZCMBxqSmMSEmMmQjAcakoBBbeBggFymW1sQC0WKB4RIx8XQC0WKB4RK0AtFigeEREeKBYwVCofOBwzFiZNLSVCMhwcMkIlS2okLCwkHDJCJUtqgYIAAAAD/+D/uANTAywAEwAuAFgAACUUDgIjIiY1ETQ+AjMyHgIVARQOAiMhIiY1ETQ+AjMyHgIdATMyHgIlNC4CIyIOAh0BJisBNTQuAiMiDgIVERQWMyEyNxUUFjMyPgI1AwsRHigWLEARHScXFigeEf77ER4oFv77LEARHScXFigeEZgWKB4RAU0cMkIlJkIwHCgpUBwyQiUmQjAcakoBBSkoakolQjIcbRcnHhFALQIKFigeEREeKBb++xcnHhFALQEFFigeEREeKBaYER4o7yVCMhwcMkIlYxNQJUIyHBwyQiX++0tqE2NLahwyQSYAAAAE/+D/uANTAywAEwAnAEcAeQAAJRQOAiMhIiY1ND4CMyEyHgIDND4CMyEyHgIVFA4CIyEiJgEUDgIjIiY1NCYjIiY1ND4CMzIeAhUUFxYzMhcWFzQvAT4DNTQuAiMhIgYHLgEjIg4CFRQXFh8BDgMVFBYzITI2NxcWMzI+AgIGER4oFv77LEARHScXAQUWKB4R2REdJxcBBRYoHhERHigW/vssQAHeER4oFixAWj+Z2BEdJxcWKB4RLC4+mWxtSIIhIjwsGRwyQiX++ydDGRlDJiZCMByBCAgQIzsrGGpKAQUmRBkDNUolQjIcbRcnHhFALRYoHhERHigB9BYoHhERHigWFyceEUD+IxcnHhFALT5a2JoWKB4RER4oFj4uLG1smbeBHgMfMD8jJUIyHB4aGh4cMkIluIEIBw4EHzA+I0tqHhoDNRwyQQAAAAP/3/+2A2cDPwAEACcAQQAAJTI3IxYlFAcGIyImNTQ3NjMhMh4CFRQHBgcGBwYjISIHITIXHgIXNCcmJzY3NjQnLgEnJiMhIgcGFRQAMzI3NgGjPy7aLAG8cG+cnN5vcJsBCxYqHhIJCg4PFRMY/vVALQF4GBMVHhJJDw8bGw8PDg8yIiAo/vW7hYQBCLy7hIXfLCycnHBv3p2cb3ASHioWGBMWDg8JCC0ICR4qFiciIhoaIiJQICIyDw6FhLu9/viEhQAC/9//tgNnAz8AGwA8AAAlFA4CIyImNREhIicmNTQ3Njc+ATMhMh4CFTM0Jy4BJyYjISIHDgEHBhUUFxYzIREUFxYzMjc+ATc2NQMeEh4qFi1C/lkuICEJCg0PKBgCFhYqHhJJDg8yIiAo/eopICQuDw83NkwBXjY3SyYiIjIPDnAYKB4SQi4BpyAhLhYVFw0PEhIeKhYoICIyDw4OEDAjIiZMNzb+o002Nw8PMiEfKgAAAAAE/9//tgNnAz8ABgALADEAWwAAJSYnJiMiBxEWMzI3FxYXFhUUDgIjISImNTQ3NjcmJyY1NDc2Nz4BMyEyHgIVFAcGNzQnLgEnJiMhIgcOAQcGFRQXFhcGBwYVFBYzITI3PgE3NjU0JyYnNjc2AhAXGhkjQSwtQD4vnzcbHRIeKhb96i1CHRs3NxsdCQoNDygYAhYWKh4SHRuBDg8yIiAo/eopICQuDw8XFykoGBduSwIWJiIiMg8OFhcqKxYW3xUMCywBOC0tnDdCRkwYKB4SQi5MRkI3N0JGTBYVFw0PEhIeKhZMRkLUKCAiMg8ODhAwIyImSUVGNzdHRUhMbg8PMiEfKktCRTk6Q0IAAv/f/7YDZwM/ACsASQAAJRQOAiMiJjURNCcmKwEWMzIXHgEXFhUUBw4CIyImNTQ3Njc+ATMhMhYVMzQnJiMhIgcOAQcGFRQAMzI3FRQXFjMyNz4BNzY1Ax4SHioWLUIuLz9tLUAYExUeCQgICR4qFpzeCQoNDygYAQub4EmFhLv+9SkgJC4PDwEIvCwnNjdLJiIiMg8OcBgoHhJCLgELPy4vLQgJHhUTGBsRFB4S3p0WFRcNDxLgm7uEhQ4QMCMiJrz++BNlTTY3Dw8yIR8qAAAADgCuAAEAAAAAAAAAGwA4AAEAAAAAAAEABQBgAAEAAAAAAAIABwB2AAEAAAAAAAMAIgDEAAEAAAAAAAQABQDzAAEAAAAAAAUADwEZAAEAAAAAAAYABQE1AAMAAQQJAAAANgAAAAMAAQQJAAEACgBUAAMAAQQJAAIADgBmAAMAAQQJAAMARAB+AAMAAQQJAAQACgDnAAMAAQQJAAUAHgD5AAMAAQQJAAYACgEpAEMAbwBwAHkAcgBpAGcAaAB0ACAAKABjACkAIAAyADAAMgAyACwAIABSAGEAdgBvAG4AdQBzAABDb3B5cmlnaHQgKGMpIDIwMjIsIFJhdm9udXMAAE0AYQBmAGkAYQAATWFmaWEAAFIAZQBnAHUAbABhAHIAAFJlZ3VsYXIAAEYAbwBuAHQARgBvAHIAZwBlACAAMgAuADAAIAA6ACAATQBhAGYAaQBhACAAOgAgADEAMwAtADEAMQAtADIAMAAyADIAAEZvbnRGb3JnZSAyLjAgOiBNYWZpYSA6IDEzLTExLTIwMjIAAE0AYQBmAGkAYQAATWFmaWEAAFYAZQByAHMAaQBvAG4AIAAwADAAMQAuADAAMAAwAABWZXJzaW9uIDAwMS4wMDAAAE0AYQBmAGkAYQAATWFmaWEAAAAAAAIAAAAAAAD/tAAzAAAAAAAAAAAAAAAAAAAAAAAAAAAAGwAAAAEAAgAGAAsADAATABQAFQAWABcAGAAZABoAGwAcACIAIwAkACUAJgAnACgAKQAqACsALAAAAAH//wACAAEAAAAAAAAADAAUAAQAAAACAAAAAQAAAAEAAAAAAAEAAAAA3kztOAAAAADflduAAAAAAN+WHt0=) format(truetype); } .ls{letter-spacing: .055em;} .hide{animation: showhide 1s ease;opacity:1;}.hide:hover {animation: hideshow .5s ease;opacity:0;}@keyframes hideshow {0% { opacity: 1; }10% { opacity: 0.9; }15% { opacity: 0.7; }30%{opacity:0.5;}100%{opacity:0;}}@keyframes showhide{0%{opacity:0;}10%{opacity:0.2;}15%{opacity:0.4;}30%{opacity:0.6;}100%{opacity: 1;}}</style>"
    ];
    string[] private svg = [
        "<svg x='",
        "' y='",
        "' overflow='visible'>",
        "</svg>"
    ];

    string[] private bgSvgGrad = [
        "<defs><linearGradient id='d' y2='1' x2='0'><stop stop-color='",
        "' offset='0'/><stop stop-color='",
        "' offset='1'/></linearGradient></defs><rect width='100%' height='100%' fill='url(#d)'/>"
    ];

    string[] private bodySvg = [
        "<path transform='matrix(1 0 .001512 1 -1.8639 -196.71)' d='m853.22 1144.8 632.11 213.51h-1264.2l632.11-213.51z' fill='url(#s)' stroke='#000' stroke-width='7' paint-order='stroke'/>"
    ];

    string[] private mouthSVG = [
        "<path d='M502.5 900h298.951v75.869H502.5z' stroke='#000' stroke-width='5' fill='",
        "' />"
    ];

    string[] private headSvg = [
        "<path d='M805-5v810H-5V-5'/><path d='M0 0v800h800V0' fill='url(#s)'/>"
    ];

    string[] private eyeSvg = [
        "<svg fill='",
        "' stroke='#000' stroke-width='4'><path d='M650 500h100v100H650z' fill='#fff'/><path d='m676.7 526.15h45.283v45.283h-45.283z'/><path d='m690.9 539.7h16.898v16.898h-16.898z' fill='#000'/><path d='m1e3 500h100v100h-100z' fill='#fff'/><path d='m1026.7 526.15h45.283v45.283h-45.283z'/><path d='m1040.9 539.7h16.898v16.898h-16.898z' fill='#000'/></svg>"
    ];

    string[] private shirtSVG = [
        "<path d='m1852.4 196.54h230.12v3.455h-230.12z'/><svg fill='",
        "' overflow='visible'><path d='m1874.2 200h95.397l630.42 174.6h-1264.3l516.11-174.6h22.359z'/><path d='m1961.3 200 638.74 174.4-514.61-174.4h-123.13z'/></svg>"
    ];

    string[] private hairSVG = [
        "<defs><linearGradient id='h'><stop stop-color='",
        "'/></linearGradient></defs><path d='M500 500.334h104.4v4.545H500z'/><path d='M599.788783 501.028577v-99.362h4.581v99.362z'/><path d='M599.788 401.664h600.143v4.555H599.788z'/><path d='M1199.931141 401.664008v100h-4.534v-100z'/><path d='M1301.87 505.443h-106.473v-4.559h106.473z'/><path fill='url(#h)' d='M500.145 247.757h799.767v153.711H500.145z' data-bx-origin='0.397 0.801'/><path fill='url(#h)' d='M500.145 401h100v100h-100zm699.767 0h100v100h-100z'/>"
    ];

    string[] private ponyTailSVG = [
        "<defs><linearGradient id='h' ><stop stop-color='",
        "'/></linearGradient></defs><path d='M1300 605.948h-103.62v-5H1300zM500 700h100v4.043H500zm103.9596-199.9996v204.043h-3.959v-204.043zm0-.0015 99.8119-.1033.0042 4.066-99.8119.1033z'/><path d='m700.13 499.9v-99.791h3.64v99.791z'/><path d='m700 400 300 0.105-0.0015 4.307-300-0.105z'/><path d='m1002 400.11v99.895h-4.492v-99.895zm-4.3237 99.898 206.25-0.02 4e-4 4.119-206.25 0.02z'/><path d='m1199.9 499.98 0.4586 100.2-4.001 0.0183-0.4585-100.2z'/><svg fill='url(#h)' overflow='visible'><path d='M500 248h800v153H500z'/><path d='m1e3 400h300v101h-300z'/><path d='M1200 500h100v101.5h-100zM500 400h200v101H500z'/><path d='M500 500h100v200H500z'/><path d='m497.49 1053h175v227h-175z' stroke='#000' stroke-width='6'/></svg>"
    ];

    string[] private eyelidsSVG = [
        "<path d='M650 498h100v26.154H650zm350 0h100v26.154h-100z' stroke='#000' stroke-width='1' fill='url(#s)'><animateTransform id='w' begin='0s;b.end' dur='3.5s' from='0' to='0'/><animateTransform id='b1' attributeName='transform' type='translate' additive='sum' begin='w.end' dur='1s' values='1 1;1 -500.4;1 1'/><animateTransform id='b' attributeName='transform' type='scale' additive='sum' begin='w.end' dur='1s' values='1 1;1 2;1 1'/></path><svg y='5.9%'><path d='M650 498h100v26.154H650zm350 0h100v26.14h-100z' class='blinkBotto' stroke='#000' stroke-width='1' fill='url(#s)'><animateTransform id='b1' attributeName='transform' type='translate' additive='sum' begin='w.end' dur='1s' values='1 1;1 -520.4;1 1'/><animateTransform id='b' attributeName='transform' type='scale' additive='sum' begin='w.end' dur='1s' values='1 1;1 2;1 1'/></path></svg>"
    ];

    string[] private eyebrowsSVG = [
        "<path d='M650 468h100v21.658H650zm350 0h100v21.658h-100z' fill='url(#h)' stroke='#000' stroke-width='5'/>"
    ];

    string[] private noseSVG = [
        "<path d='m424.37 720.47 75.633 131h-151.27l75.634-131z'  fill-opacity='0.035' stroke='#000' stroke-width='4' data-bx-shape='triangle 348.733 720.474 151.267 131.002 0.5 0 [email protected]'/>"
    ];

    string[] private earSVG = [
        "<defs><linearGradient id='s' ><stop stop-color='",
        "'/></linearGradient></defs><path id='c' d='m428.4 406.29a43.415 43.415 0 1 1 0 43.415 21.809 21.809 0 0 0 0-43.415z' stroke='#000' stroke-width='4.9975' data-bx-shape='crescent 466 428 43.415 300 0.294 [email protected]'/><svg width='909.76' height='113.77' fill='url(#s)' viewBox='513.126 535.454 909.759 113.767'><use transform='matrix(-.020544 1.0313 -.9438 -.018801 969.89 130.91)' stroke-width='4.9975' data-bx-shape='crescent 466 428 43.415 300 0.294 [email protected]' href='#c'/><path d='m517.02 541.73h80.115v64.604h-80.115z'/><path d='m513.13 536.52h4.652v70.911h-4.652z' fill='#000'/><path d='m513.4 536.36h86.471v5.369h-86.471z' fill='#000'/><use transform='matrix(.020544 1.0311 .9438 -.03106 966.12 135.93)' stroke-width='4.9975' data-bx-shape='crescent 466 428 43.415 300 0.294 [email protected]' href='#c'/><path d='m1419 540.87-80.115 1.0406v64.604l80.115-1.0406z'/><path d='m1422.9 535.61-4.6516 0.0604v70.911l4.6516-0.0605z' fill='#000'/><path d='m1422.6 535.45-86.471 1.1231v5.3695l86.471-1.1232z' fill='#000'/></svg>"
    ];

    string[] private glassesSVG = [
        "<svg class='hide' fill='",
        "' stroke='#000' stroke-width='4' overflow='visible'><path id='a' d = 'M596.99 343.333a89.677 89.677 0 1 0 179.354 0 89.677 89.677 0 1 0-179.354 0Zm11.715 0a77.962 77.962 0 0 1 155.924 0 77.962 77.962 0 0 1-155.924 0Z' transform = 'matrix(0 1 -1 .006581 980.105379 -107.225916)' /> <use href='#a' transform = 'matrix(0 1.02 -1 .006581 1569.4 -72.789584)' /> <path fill='#000' d = 'M 724.62 558.604 L 725.347 562.943 L 899.897 561.465 L 899.988 558.987' /> <path stroke='none' d = 'M 723.157 573.059 L 717.611 563.6 L 797.188 562.877 L 847.521 563.092 L 902.257 562.955 L 900.21 572.654' /> <path fill='#000' stroke = 'none' d = 'M 725.12 573.169 L 814.429 568.607 L 900.089 572.782 L 899.564 578.436 C 899.564 578.436 902.76 577.146 881.588 576.006 C 866.636 575.201 832.73 573.088 814.588 573.066 C 799.307 573.047 783.958 574.454 770.486 575.385 C 726.313 578.439 726.018 576.404 726.018 576.818' /> <path d='M 1067.375 544.94 L 1214.175 509.35 L 1213.788 509.164 L 1073.393 560.666 M 561.189 538.644 L 556.386 536.943 L 518.62 527.298 L 409.5 501.267 L 414.616 500.766 L 555.071 552.439' /> <svg fill='",
        "' opacity='",
        "%'><circle cx='637' cy='582' r='79'/><circle cx='988' cy='580.5' r='79'/></svg></svg>"
    ];

    string[] private mafiaHatSVG = [
        '<g stroke="#000" stroke-width=".408" fill="',
        '"><path d="m102.2 47.2-12.5 6.7c-4 1.5-6 1.5-10.8 0l-14.2-6.7c-4.5-1-15.1 2.3-15 5.1 0 0-3.4 21.2-10.0 28.4-1.4 1.6 1.6.4 14.6.4s.4.7 73.9-1.002c-6.626-7.879-10.66-27.9-10.6-27.9-.0-2.8-10.2-7.4-15.1-5" transform="matrix(9.086 .045 -.02 5.7 54 -271)"/><path fill="',
        '" d="m42.2 81.2 83.5-.1c1.1 0 2.2-1.2 2.2-.05l.2 10.8c0 1.19-.97 2.16-2.16 2.16H41.3A2.1 2.166 0 0 1 39.2 91.98l-.034-10.9c0-1.2 1.8.2 3.07.2Z" transform="matrix(9.08 0 0 5.7 52 -267.7)"/><path d="M30.373 86.041c1.918-.795 3.163 2.418 3.163 2.418l100.814 1s1.641-2.238 2.904-2.235c2.448.006 1.394 4.602 1.394 4.602s-1.7 6.6-4.3 6.5c-4.5-1.9-5.7-2.5-99.8-1.2-1.7.0-3.9-2.7-4.6-4.9-.4-1.5-1.4-5.48.5-6" transform="matrix(9 -.04 .2 5.6 42 -263)"/></g>'
    ];

    //        uint256 svgId;
    //    uint256 colorId;
    //    uint256 varCount;

    //        colorMapping2[0] = 0;
    // svgLayers[_id].attributes[listId] = SVGAttributes(
    //     1,
    //     0,
    //     1,
    //     colorMapping2
    // );

    struct AddAttribute {
        uint32 id;
        string[] svg;
        uint256[] colorMapping;
    }

    struct TokenLayers {
        uint256[] attributes;
        uint256 aId;
        mapping(uint256 => bytes) colors;
    }

    struct TokenRevealInfo {
        bool isMafia;
        bool revealed;
        uint256 seed;
        uint256 season;
        uint256 count;
        mapping(uint256 => TokenLayers) layers;
    }
    struct TokenLayerInfo {
        uint32 layer;
    }

    struct Eyes {
        mapping(uint256 => bytes32) name;
        mapping(uint256 => bytes) eyeColors;
    }

    struct Drops {
        bytes ipfsHash;
        bytes ipfsPreview;
        uint16 id;
        uint16 revealStage;
        uint256 snapshot;
    }

    struct Backgrounds {
        mapping(uint256 => bytes32) backgroundType;
        mapping(uint256 => bytes) gradientColors;
    }

    struct Species {
        mapping(uint256 => bytes32) name;
        mapping(uint256 => bytes) speciesColors;
    }

    Backgrounds private backgrounds;
    Species private species;
    Eyes private eyes;

    struct GradientBGs {
        bytes color;
    }

    // struct DropInfo {
    //     uint16 id;
    //     uint256 snapshot;
    //     uint256 baseIPFS;
    //     uint256 previewIPFS;
    //     mapping(uint256 => HashInfo) hashes;
    // }

    struct TokenInfo {
        uint16 stage;
        uint256 lastToken;
        uint256 hash;
    }

    struct RevealToken {
        uint8 v;
        uint256 drop;
        uint256 index;
        bytes32 r;
        bytes32 s;
        uint256 tokenId;
    }

    struct SVGInfo {
        bytes name;
        uint256 count;
        mapping(uint256 => SVGLayer) layer;
    }

    struct SVGLayer {
        bool inactive;
        uint256 remaining;
        string x;
        string y;
        string[] svg;
    }

    struct SVGLayers {
        bytes name;
        uint256 layerCount;
        mapping(uint256 => SVGAttributes) attributes;
    }

    struct Colors {
        bytes name;
        uint256 count;
        mapping(uint256 => bytes) list;
    }

    struct SVGAttributes {
        uint256 svgId;
        uint256 colorId;
        uint256 varCount;
        uint256[] colorMapping;
    }

    struct AttributeMapping {
        bytes name;
        uint256 attributeCount;
        mapping(uint256 => Attribute) info;
    }

    struct Attribute {
        mapping(uint256 => bool) isNumber;
        mapping(uint256 => uint256[2]) range;
        bool inactive;
        uint256 remaining;
        uint256 colorId;
        uint256 varCount;
        string x;
        string y;
        string[] svg;
    }

    struct Accessories {
        uint256 position;
        uint256 id;
    }

    mapping(uint256 => uint256) internal familiarUnlocked;

    mapping(uint256 => Accessories) public accessories;

    //     struct SVGInfo {
    //     bytes name;
    //     uint256 count;
    //     mapping(uint256 => SVGLayer) layer;
    // }

    // struct SVGLayer {
    //     bool inactive;
    //     uint256 remaining;
    //     string x;
    //     string y;
    //     string[] svg;
    // }

    // mapping(uint32 => SVGInfo) private svgList;

    mapping(address => uint256) public nonces;
    mapping(uint256 => Drops) private drops;
    mapping(uint256 => TokenRevealInfo) public tokens;

    mapping(uint256 => Colors) private colors;
    mapping(uint256 => SVGLayers) public svgLayers;

    mapping(uint256 => AttributeMapping) public attributes;

    mapping(uint256 => bool) public tokenLayers;

    uint256[] attributeLayerGlasses = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    uint256[] attributeLayerNoGlasses = [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11];

    /// mapping(uint256 => TokenInfo) public tokenInfo;

    constructor(address _NEO) ERC721G("AIAlbumsMint", "AIA", 0, 10000) {
        // tokenLayers[0] = true;
        // tokenLayers[1] = true;
        // tokenLayers[2] = true;
        // tokenLayers[3] = true;
        // tokenLayers[4] = true;
        // tokenLayers[5] = true;
        // tokenLayers[7] = true;
        // tokenLayers[8] = true;
        // tokenLayers[9] = true;
        // tokenLayers[10] = true;
        // tokenLayers[11] = true;

        accessories[0] = Accessories(6, 6);

        // attributes[0].colorId = 0;
        // attributes[0].svgId = 0;

        //        bool isNumber;
        // bool inactive;
        // uint256 remaining;
        // uint256 colorId;
        // uint256 varCount;
        // uint256[2] range;
        // string x;
        // string y;
        // string[] svg;
        attributes[0].name = "Backgrounds";
        attributes[0].attributeCount = 1;
        attributes[0].info[0].svg = bgSvgGrad;
        svgLayers[0].layerCount = 1;
        attributes[0].info[0].range[0] = [0, 21];
        attributes[0].info[0].range[1] = [0, 21];

        attributes[1].name = "Ears";
        attributes[1].attributeCount = 1;
        attributes[1].info[0].svg = earSVG;
        attributes[1].info[0].colorId = 1;
        attributes[1].info[0].x = "15.6%";
        attributes[1].info[0].y = "42.5%";
        svgLayers[1].layerCount = 1;

        attributes[2].name = "Head";
        attributes[2].attributeCount = 1;
        attributes[2].info[0].svg = headSvg;
        attributes[2].info[0].colorId = 1;
        attributes[2].info[0].x = "20%";
        attributes[2].info[0].y = "20%";
        svgLayers[2].layerCount = 1;

        // attributes[12].name = "Glasses";
        // attributes[12].attributeCount = 1;
        // attributes[12].info[0].varCount = 3;
        // attributes[12].info[0].svg = glassesSVG;
        // attributes[12].info[0].colorId = 0;
        // attributes[12].info[0].x = "-12.2%";
        // attributes[12].info[0].y = "3.8%";
        // attributes[12].info[0].range[2] = [75, 98];
        // svgLayers[12].layerCount = 1;
        // attributes[12].info[0].isNumber[2] = true;

        // attributes[3].info[0] = Attribute(
        //     false,
        //     1,
        //     1,
        //     [uint256(0), uint256(0)]
        // );

        // svgLayers[3].layerCount = 1;

        attributes[3].name = "Eyes";
        attributes[3].attributeCount = 1;
        attributes[3].info[0].varCount = 1;
        attributes[3].info[0].svg = eyeSvg;
        attributes[3].info[0].colorId = 5;
        attributes[3].info[0].x = "-17.35%";
        attributes[3].info[0].y = "5.5%";
        svgLayers[3].layerCount = 1;

        attributes[4].name = "Brows";
        attributes[4].attributeCount = 1;
        attributes[4].info[0].varCount = 0;
        attributes[4].info[0].svg = eyebrowsSVG;
        attributes[4].info[0].colorId = 7;
        attributes[4].info[0].x = "-17.35%";
        attributes[4].info[0].y = "5.5%";
        svgLayers[4].layerCount = 1;

        attributes[5].name = "Eye Lids";
        attributes[5].attributeCount = 0;
        attributes[5].info[0].varCount = 0;
        attributes[5].info[0].svg = eyelidsSVG;
        attributes[5].info[0].colorId = 1;
        attributes[5].info[0].x = "-17.35%";
        attributes[5].info[0].y = "5.5%";
        svgLayers[5].layerCount = 1;

        attributes[6].name = "Glasses";
        attributes[6].attributeCount = 1;
        attributes[6].info[0].varCount = 3;
        attributes[6].info[0].svg = glassesSVG;
        attributes[6].info[0].x = "-12.2%";
        attributes[6].info[0].y = "3.8%";
        attributes[6].info[0].range[2] = [75, 98];
        svgLayers[6].layerCount = 1;
        attributes[6].info[0].isNumber[2] = true;
        attributes[6].info[0].range[0] = [22, 30];
        attributes[7].info[0].range[1] = [0, 21];

        attributes[7].name = "Hair";
        attributes[7].attributeCount = 2;
        attributes[7].info[0].varCount = 1;
        attributes[7].info[0].svg = hairSVG;
        attributes[7].info[1].svg = ponyTailSVG;
        attributes[7].info[0].colorId = 7;
        attributes[7].info[1].colorId = 7;
        attributes[7].info[0].x = "-19.065%";
        attributes[7].info[0].y = "0.5%";
        attributes[7].info[1].x = "-19.065%";
        attributes[7].info[1].y = "0.5%";
        svgLayers[7].layerCount = 2;

        attributes[8].name = "Body";
        attributes[8].attributeCount = 1;
        attributes[8].info[0].varCount = 1;
        attributes[8].info[0].svg = bodySvg;
        attributes[8].info[0].colorId = 1;
        attributes[8].info[0].x = "-17.2%";
        attributes[8].info[0].y = "8.9%";
        svgLayers[8].layerCount = 1;

        attributes[9].name = "Mouth";
        attributes[9].attributeCount = 1;
        attributes[9].info[0].varCount = 1;
        attributes[9].info[0].svg = mouthSVG;
        attributes[9].info[0].colorId = 8;
        svgLayers[9].layerCount = 1;

        attributes[10].name = "Shirt";
        attributes[10].attributeCount = 1;
        attributes[10].info[0].varCount = 1;
        attributes[10].info[0].svg = shirtSVG;
        attributes[10].info[0].colorId = 6;
        attributes[10].info[0].x = "-104.3%";
        attributes[10].info[0].y = "70.425%";
        svgLayers[10].layerCount = 1;

        attributes[11].name = "Nose";
        attributes[11].attributeCount = 1;
        attributes[11].info[0].varCount = 0;
        attributes[11].info[0].svg = noseSVG;
        attributes[11].info[0].colorId = 1;
        attributes[11].info[0].x = "18%";
        svgLayers[11].layerCount = 1;

        attributes[12].name = "Earings";
        attributes[12].attributeCount = 1;
        attributes[12].info[0].varCount = 0;
        attributes[12].info[0].colorId = 1;
        attributes[12].info[0].svg = [""];
        attributes[12].info[0].x = "16.9%";
        attributes[12].info[0].y = "47.5%";
        svgLayers[12].layerCount = 1;

        attributes[13].name = "Hat";
        attributes[13].attributeCount = 1;
        attributes[13].info[0].svg = mafiaHatSVG;
        attributes[13].info[0].colorId = 6;
        attributes[13].info[0].x = "-12%";
        attributes[13].info[0].y = "4.5%";
        svgLayers[13].layerCount = 1;

        // uint256[] memory colorMapping1 = new uint256[](2);
        // colorMapping1[0] = 0;
        // colorMapping1[1] = 1;
        // uint256[] memory colorMapping2 = new uint256[](1);
        // // colorMapping2[0] = 0;
        // uint256[] memory colorMapping3 = new uint256[](1);

        // uint256[] memory colorMapping5 = new uint256[](0);

        // uint256[] memory colorMapping4 = new uint256[](3);

        // uint256[] memory colorMapping6 = new uint256[](6);

        // svgList[0].count = 1;
        // svgList[0].name = "Backgrounds";
        // svgList[0].layer[0].svg = bgSvgGrad;
        // // svgList[0].list[1] = bgSvgSolid;

        // svgLayers[0].name = "background";
        // svgLayers[0].attributes[0] = SVGAttributes(0, 0, 2, colorMapping1);
        // colorMapping1[1] = 0;

        // svgList[1].count = 1;
        // svgList[1].name = "Ears";
        // svgList[1].layer[0].svg = earSVG;
        // svgList[1].layer[0].x = "15.6%";
        // svgList[1].layer[0].y = "42.5%";
        // svgLayers[1].name = "ears";
        // svgLayers[1].attributes[0] = SVGAttributes(0, 1, 1, colorMapping3);

        // svgList[2].count = 1;
        // svgList[2].name = "Head";
        // svgList[2].layer[0].svg = headSvg;
        // svgList[2].layer[0].x = "20%";
        // svgList[2].layer[0].y = "20%";
        // svgLayers[2].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);
        // //    svgList[1].layer[0].list[0];
        // // svgLayers[1].name = "head";

        // // svgList[3].count = 1;
        // // svgList[3].name = "Glasses";
        // // svgList[3].layer[0].svg = [""];
        // // svgList[3].layer[0].x = "-19.5%";
        // // svgList[3].layer[0].y = "-0.5%";
        // // svgLayers[3].name = "glasses";
        // // // svgLayers[3].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);
        // // svgLayers[3].attributes[0] = SVGAttributes(0, 0, 3, colorMapping4);

        // svgList[3].count = 2;
        // svgList[3].name = "Hair";
        // svgList[3].layer[0].svg = hairSVG;
        // svgList[3].layer[1].svg = ponyTailSVG;

        // svgList[3].layer[0].x = "-19.065%";
        // svgList[3].layer[0].y = "0.5%";
        // svgList[3].layer[1].x = "-19.065%";
        // svgList[3].layer[1].y = "0.5%";
        // svgLayers[3].name = "hair";
        // svgLayers[3].attributes[0] = SVGAttributes(0, 7, 1, colorMapping3);
        // svgLayers[3].attributes[1] = SVGAttributes(1, 7, 1, colorMapping3);

        // svgList[4].count = 1;
        // svgList[4].name = "Body";
        // svgList[4].layer[0].svg = bodySvg;
        // svgList[4].layer[0].x = "-17.2%";
        // svgList[4].layer[0].y = "8.9%";
        // svgLayers[4].name = "body";
        // svgLayers[4].attributes[0] = SVGAttributes(0, 1, 1, colorMapping3);

        // svgList[5].count = 1;
        // svgList[5].name = "Eyes";
        // svgList[5].layer[0].svg = eyeSvg;
        // svgList[5].layer[0].x = "-17.35%";
        // svgList[5].layer[0].y = "5.5%";
        // svgLayers[5].name = "eyes";
        // svgLayers[5].attributes[0] = SVGAttributes(0, 5, 1, colorMapping3);

        // svgList[6].count = 1;
        // svgList[6].name = "Mouth";
        // svgList[6].layer[0].svg = mouthSVG;
        // svgLayers[6].name = "mouths";
        // svgLayers[6].attributes[0] = SVGAttributes(0, 8, 1, colorMapping3);

        // svgList[7].count = 1;
        // svgList[7].name = "Shirt";
        // svgList[7].layer[0].svg = shirtSVG;
        // svgList[7].layer[0].x = "-104.3%";
        // svgList[7].layer[0].y = "70.425%";
        // svgLayers[7].name = "shirt";
        // svgLayers[7].attributes[0] = SVGAttributes(0, 6, 1, colorMapping3);

        // svgList[9].count = 1;
        // svgList[9].name = "Eye Lids";
        // svgList[9].layer[0].svg = eyelidsSVG;
        // svgList[9].layer[0].x = "-17.35%";
        // svgList[9].layer[0].y = "5.5%";
        // svgLayers[9].name = "eyelids";
        // svgLayers[9].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);

        // svgList[8].count = 1;
        // svgList[8].name = "Brows";
        // svgList[8].layer[0].svg = eyebrowsSVG;
        // svgList[8].layer[0].x = "-17.35%";
        // svgList[8].layer[0].y = "5.5%";
        // svgLayers[8].name = "brows";
        // svgLayers[8].attributes[0] = SVGAttributes(0, 7, 0, colorMapping5);

        // svgList[10].count = 1;
        // svgList[10].name = "Nose";
        // svgList[10].layer[0].svg = noseSVG;
        // svgList[10].layer[0].x = "18%";
        // svgLayers[10].name = "nose";
        // svgLayers[10].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);

        // svgList[11].count = 1;
        // svgList[11].name = "Earings";
        // svgList[11].layer[0].svg = ["erk"];
        // svgList[11].layer[0].x = "16.9%";
        // svgList[11].layer[0].y = "47.5%";
        // svgLayers[11].name = "earings";

        //svgLayers[11].attributes[0] = SVGAttributes(0, 1, 0, colorMapping5);

        //<svg x="-87.3%" y="61.5%"

        //make new array with 2 elements

        //        svgLayers[0].attributes[1] = SVGAttributes(1, 0, 1, colorMapping2);

        colors[0].name = "bg";
        colors[0].count = 21;
        colors[0].list[0] = "#FF0000"; //red
        colors[0].list[1] = "#EDB9B9"; //light red (pink)
        colors[0].list[2] = "#8F2323"; //dark red
        colors[0].list[3] = "#FF7F7F"; //pink
        colors[0].list[4] = "#E7E9B9"; //yellow-green
        colors[0].list[5] = "#8F6A23"; //yellow-brown
        colors[0].list[6] = "#737373"; //grey
        colors[0].list[7] = "#FFD400"; //dark-yellow
        colors[0].list[8] = "#B9EDE0"; //pastel blue
        colors[0].list[9] = "#4F8F23"; //dark green
        colors[0].list[10] = "#CCCCCC"; //light grey
        colors[0].list[11] = "#FFFF00"; //yellow
        colors[0].list[12] = "#B9D7ED"; //light blue
        colors[0].list[13] = "#23628F"; // dark cyan
        colors[0].list[14] = "#BFFF00"; //lime green
        colors[0].list[15] = "#DCB9ED"; //light purple
        colors[0].list[16] = "#6B238F"; //dark purple
        colors[0].list[17] = "#6AFF00"; //neon reen
        colors[0].list[18] = "#00EAFF"; //cyan
        colors[0].list[19] = "#0095FF"; //blue
        colors[0].list[20] = "#0040FF"; //dark blue

        //glass rim colors (for glasses)

        colors[0].list[21] = "#000000"; //black
        colors[0].list[22] = "#FFFFFF"; //white
        colors[0].list[23] = "#FF0000"; //red
        colors[0].list[24] = "#FFFF00"; //yellow
        colors[0].list[25] = "#00FF00"; //green
        colors[0].list[26] = "#00FFFF"; //cyan
        colors[0].list[27] = "#0000FF"; //blue
        colors[0].list[28] = "#FF00FF"; //magenta
        colors[0].list[29] = "#FF7F7F"; //pink

        species.name[0] = "Human";
        species.name[1] = "Alien";
        species.name[2] = "Robot";
        species.name[3] = "Nanik";
        species.speciesColors[0] = "#C58C85";
        species.speciesColors[1] = "#ECBCB4";
        species.speciesColors[2] = "#D1A3A4";
        species.speciesColors[3] = "#A1665e";
        species.speciesColors[4] = "#503335";

        colors[4].name = "Nanik";
        colors[4].count = 5;
        colors[4].list[0] = "#C58C85";
        colors[4].list[1] = "#ECBCB4";
        colors[4].list[2] = "#D1A3A4";
        colors[4].list[3] = "#A1665e";
        colors[4].list[4] = "#503335";

        colors[3].name = "Robot";
        colors[3].count = 5;
        colors[3].list[0] = "#C58C85";
        colors[3].list[1] = "#ECBCB4";
        colors[3].list[2] = "#D1A3A4";
        colors[3].list[3] = "#A1665e";
        colors[3].list[4] = "#503335";

        colors[2].name = "Alien";
        colors[2].count = 5;
        colors[2].list[0] = "#C58C85";
        colors[2].list[1] = "#ECBCB4";
        colors[2].list[2] = "#D1A3A4";
        colors[2].list[3] = "#A1665e";
        colors[2].list[4] = "#503335";

        colors[1].name = "humans";
        colors[1].count = 5;
        colors[1].list[0] = "#C58C85";
        colors[1].list[1] = "#ECBCB4";
        colors[1].list[2] = "#D1A3A4";
        colors[1].list[3] = "#A1665e";
        colors[1].list[4] = "#503335";

        colors[8].name = "human-lips";
        colors[8].count = 5;
        colors[8].list[0] = "#D99E96";
        colors[8].list[1] = "#F2C7C2";
        colors[8].list[2] = "#E2B2B0";
        colors[8].list[3] = "#B17F7A";
        colors[8].list[4] = "#5F3F3B";

        colors[9].name = "lipstick";
        colors[9].count = 5;
        colors[9].list[0] = "#E35D6A";
        colors[9].list[1] = "#F7A5B0";
        colors[9].list[2] = "#F28E9B";
        colors[9].list[3] = "#C65E6A";
        colors[9].list[4] = "#6F2F35";

        colors[5].name = "eyes";
        colors[5].count = 10;
        colors[5].list[0] = "#76C4AE";
        colors[5].list[1] = "#9FC2BA";
        colors[5].list[2] = "#BEE9E4";
        colors[5].list[3] = "#7CE0F9";
        colors[5].list[4] = "#CAECCF";
        colors[5].list[5] = "#D3D2B5";
        colors[5].list[6] = "#CABD80";
        colors[5].list[7] = "#E1CEB1";
        colors[5].list[8] = "#DDB0A0";
        colors[5].list[9] = "#D86C70";

        colors[6].name = "shirt";
        colors[6].count = 17;
        colors[6].list[0] = "#FFFBA8";
        colors[6].list[1] = "#693617";
        colors[6].list[2] = "#650C17";
        colors[6].list[3] = "#7BDE4E";
        colors[6].list[4] = "#EB9B54";
        colors[6].list[5] = "#FF5E00";
        colors[6].list[6] = "#202020";
        colors[6].list[7] = "#3E3433";
        colors[6].list[8] = "#FFB300";
        colors[6].list[9] = "#FFCFE7";
        colors[6].list[10] = "#AFAFAF";
        colors[6].list[11] = "#032D49";
        colors[6].list[12] = "#193D24";
        colors[6].list[13] = "#CE051f";
        colors[6].list[14] = "#101C86";
        colors[6].list[15] = "#1BCEfA";
        colors[6].list[16] = "#FFFFFF";

        colors[7].name = "hair";
        colors[7].count = 10;
        colors[7].list[0] = "#AA8866";
        colors[7].list[1] = "#DEBE99";
        colors[7].list[2] = "#241C11";
        colors[7].list[3] = "#4F1A00";
        colors[7].list[4] = "#9A3300";
        colors[7].list[5] = "#505050";
        colors[7].list[6] = "#3264C8";
        colors[7].list[7] = "#FFFF5A";
        colors[7].list[8] = "#DC95DC";
        colors[7].list[9] = "#FE5CAA";

        NEO = _NEO;
        drops[0].id = 0;
        drops[0].snapshot = 0;
        drops[0].ipfsHash = "";
        drops[0].ipfsPreview = "QmcSQvWdTF38norhnXwcGLuCqkqY9Rfty4SfVrfBUNnpGp";

        //loop through and create tokens but low gas
    }

    modifier adminAccess() {
        require(
            msg.sender == NEO ||
                msg.sender == The_Dude ||
                msg.sender == owner(),
            "Admin Access Required"
        );
        _;
    }

    modifier onlyValidAccess(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _nonce,
        uint256 _drop,
        uint256 _index,
        address _signer
    ) {
        bytes32 hash = keccak256(
            abi.encodePacked(address(this), msg.sender, _nonce, _drop, _index)
        );
        address sender = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ),
            _v,
            _r,
            _s
        );
        require(sender == The_Dude, "Invalid access message.");
        nonces[msg.sender]++;
        _;
    }

    function addAttribute(AddAttribute memory _addAttribute)
        external
        adminAccess
    {
        attributes[_addAttribute.id]
            .info[_addAttribute.colorMapping.length]
            .svg = _addAttribute.svg;
        svgLayers[_addAttribute.id].attributes[
            attributes[_addAttribute.id].attributeCount
        ] = SVGAttributes(
            _addAttribute.colorMapping.length,
            _addAttribute.id,
            _addAttribute.colorMapping.length,
            _addAttribute.colorMapping
        );
        attributes[_addAttribute.id].attributeCount += 1;
    }

    function updateAttribute(
        uint32 id,
        uint32 layerId,
        string[] memory _svg
    ) public adminAccess {
        attributes[id].info[layerId].svg = _svg;
    }

    // function randomSpeciesColor(uint256 _seed)
    //     private
    //     view
    //     returns (bytes memory)
    // {
    //     return
    //         species.speciesColors[
    //             uint256(keccak256(abi.encodePacked(_seed, "speciesColor"))) %
    //                 speciesColorCount
    //         ];
    // }

    // function randomBackgroundType(uint256 _seed)
    //     private
    //     view
    //     returns (uint256)
    // {
    //     return _seed % bgTypeCount;
    // }

    // function generateSVG(uint32 id, uint256 _seed)
    //     internal
    //     view
    //     returns (bytes memory)
    // {
    //     uint256 svgNumber = _seed % svgList[id].count;

    //     uint256 varCount = svgLayers[id].attributes[svgNumber].varCount;
    //     uint32 oddFound = 0;
    //     uint256[] memory colorMapping = svgLayers[id]
    //         .attributes[svgNumber]
    //         .colorMapping;
    //     string[] memory _svg = svgList[id].layer[svgNumber].svg;

    //     //loop through string to create svg with required colors
    //     bytes memory svgBytes = abi.encodePacked(_svg[0]);

    //     bytes[] memory colorsArray = new bytes[](varCount);

    //     for (uint256 i = 1; i < _svg.length + varCount; i++) {
    //         //if odd then color is found
    //         if (i % 2 == 1) {
    //             colorsArray[oddFound] = colors[
    //                 svgLayers[id].attributes[svgNumber].colorId
    //             ].list[
    //                     uint256(keccak256(abi.encodePacked(i, _seed))) %
    //                         colors[id].count
    //                 ];
    //             svgBytes = abi.encodePacked(
    //                 svgBytes,
    //                 colorsArray[colorMapping[oddFound]]
    //             );
    //             oddFound++;
    //         } else {
    //             svgBytes = abi.encodePacked(svgBytes, _svg[i - oddFound]);
    //         }
    //     }
    //     if (id != 0) {
    //         svgBytes = abi.encodePacked(
    //             svg[0],
    //             svgList[id].layer[svgNumber].x,
    //             svg[1],
    //             svgList[id].layer[svgNumber].y,
    //             svg[2],
    //             svgBytes,
    //             svg[3]
    //         );
    //     }
    //     return svgBytes;
    // }

    // function generateHead(uint256 _seed) internal view returns (bytes memory) {
    //     return
    //         abi.encodePacked(
    //             headSvg[0],
    //             randomSpeciesColor(_seed),
    //             headSvg[1],
    //             randomEye(69),
    //             headSvg[1],
    //             bodySvg[0],
    //             randomSpeciesColor(_seed),
    //             bodySvg[1]
    //         );
    // }

    // function generateGradientBG(bool isSolid)
    //     internal
    //     view
    //     returns (bytes memory)
    // {
    //     //pick two random colors
    //     uint256 index1 = block.timestamp % gradientColorCount;
    //     uint256 index2 = (block.timestamp + 420) % gradientColorCount;

    //     if (isSolid) index2 = index1;

    //     if (index1 == index2 && !isSolid) {
    //         index2 = (index2 + 1) % gradientColorCount;
    //     }
    //     bytes memory c1 = backgrounds.gradientColors[index1];

    //     bytes memory c2 = backgrounds.gradientColors[index2];

    //     return
    //         abi.encodePacked(
    //             bgSvg[0],
    //             c1,
    //             bgSvg[1],
    //             c2,
    //             bgSvg[2],
    //             generateHead(block.timestamp),
    //             bgSvg[2]
    //         );
    // }

    function singatureClaimHash(
        uint256 _drop,
        uint256 _index,
        uint256 _nonce
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    msg.sender,
                    _nonce,
                    _drop,
                    _index
                )
            );
    }

    function mint(
        address _to,
        uint32 _amount,
        bool stake
    ) public {
        require(msg.sender == NEO, "Admin access only.");
        if (stake) _mintAndStake(_to, _amount);
        else _mintAndStake(_to, _amount);
    }

    function mintTest(
        address _to,
        uint32 _amount,
        bool stake
    ) public {
        if (stake) _mintAndStake(_to, _amount);
        else _mint(_to, _amount);
    }

    // set last index to receiver

    //_mint(_to, _amount);

    function randomNumber(uint256 _seed, uint256[2] memory range)
        internal
        pure
        returns (uint256)
    {
        //select random number from range
        uint256 start = range[0];
        uint256 end = range[1];

        uint256 random = (_seed % (end - start + 1)) + start;

        return random;
    }

    //delete random token from array

    //display length of token array to public
    // function getLength() public view returns (uint256) {
    //     return tokenIds.length;
    // }

    // uint8 _v,
    // bytes32 _r,
    // bytes32 _s,
    // uint16 _drop,
    // uint32 _index,
    // uint256 _tokenId

    //  function generateTraits(TokenRevealInfo calldata token) external {}

    // function revealArtTest(RevealToken calldata _revealToken)
    //     external
    // // onlyValidAccess(
    // //     _revealToken.v,
    // //     _revealToken.r,
    // //     _revealToken.s,
    // //     nonces[msg.sender],
    // //     _revealToken.drop,
    // //     _revealToken.index,
    // //     msg.sender
    // // )
    // {
    //     TokenRevealInfo storage token = tokens[_revealToken.tokenId];

    //     require(_exists(_revealToken.tokenId), "Token does not exist");
    //     require(!token.revealed, "Token already revealed");

    //     unchecked {
    //         // this.generateTraits(token);
    //         uint256 _seed = block.timestamp + block.difficulty + block.number;

    //         token.seed = _seed;

    //         bool female;
    //         token.count = 12;

    //         //make new array of bytes

    //         //generate random traits here and store in token forloop 9 for basic traits

    //         for (uint32 i = 0; i < 13; i++) {
    //             uint256 svgNumber = _seed % svgLayers[i].layerCount;

    //             //create new array of 9 empty

    //             if (i == 7 && svgNumber == 1) {
    //                 female = true;
    //                 // token.count += 1;
    //             }

    //             //attributes[i].info[svgNumber].colorId;

    //             // if (!female && svgNumber == 10) break;

    //             // uint256[] memory colorMapping = attributes[i]
    //             //     .info[svgNumber]
    //             //     .range;

    //             for (
    //                 uint32 j = 0;
    //                 j < attributes[i].info[svgNumber].svg.length - 1;
    //                 j++
    //             ) {
    //                 uint256 start = attributes[i].info[svgNumber].range[j][0];
    //                 uint256 end = attributes[i].info[svgNumber].range[j][1];
    //                 uint256 colorId = attributes[i].info[j].colorId;

    //                 if (end == 0) end = colors[colorId].count;

    //                 if (female && i == 9) {
    //                     colorId++;
    //                 }

    //                 // bytes memory color = colors[colorId].list[
    //                 //     (_seed + j) % colors[colorId].count
    //                 // ];
    //                 //colorsArray[j] = color;

    //                 token.layers[i].colors[j] = colors[colorId].list[
    //                     randomNumber(
    //                         _seed + ((i + 69) * (j + 420)),
    //                         [start, end]
    //                     )
    //                 ];
    //             }
    //             token.revealed = true;
    //         }

    //         //  uint32[] memory layers = new uint32[](8);
    //         // token.layers = new uint32[](10);

    //         // layers[0] = 0;
    //         // layers[1] = 1;
    //         // layers[2] = 2;
    //         // layers[3] = 3;
    //         // layers[4] = 4;
    //         // layers[5] = 5;
    //         // layers[6] = 6;
    //         // layers[7] = 8;
    //         // layers[8] = 8;

    //         //loop and add 2,1,3,4 layers 1000 times to test size and reveal

    //         //token.layers = layers;

    //         //token.layer[0].colors = new uint32[](1);
    //     }
    // }

    function revealArtTest(RevealToken calldata _revealToken)
        external
    // onlyValidAccess(
    //     _revealToken.v,
    //     _revealToken.r,
    //     _revealToken.s,
    //     nonces[msg.sender],
    //     _revealToken.drop,
    //     _revealToken.index,
    //     msg.sender
    // )
    {
        TokenRevealInfo storage token = tokens[_revealToken.tokenId];

        require(_exists(_revealToken.tokenId), "Token does not exist");
        require(!token.revealed, "Token already revealed");

        unchecked {
            // this.generateTraits(token);
            uint256 _seed = block.timestamp + block.difficulty + block.number;

            token.seed = _seed;

            bool female;

            uint256 count = 0;

            //make new array of bytes

            //generate random traits here and store in token forloop 9 for basic traits

            for (uint32 i = 0; i < 14; i++) {
                bool foundAttribute = true;
                uint256 svgNumber = _seed % svgLayers[i].layerCount;

                if (i == 6 || i == 12 || i == 13) {
                    foundAttribute = false;
                }

                //create new array of 9 empty

                if (i == 6 && _seed % 4 == 0) {
                    foundAttribute = true;
                }

                if (i == 7 && svgNumber == 1) {
                    female = true;
                }

                if (i == 12 && _seed % 2 == 0) {
                    foundAttribute = true;
                }

                if (i == 13 && _seed % 10 == 0) {
                    //select 1 out of 10 if true then mafia and then random hat   && _seed % 10 == 0 && (_seed * 2) % 2 == 0
                    token.isMafia = true;
                    if ((_seed * 2) % 2 == 0) foundAttribute = true;
                    // token.count += 1;
                }

                //attributes[i].info[svgNumber].colorId;

                // if (!female && svgNumber == 10) break;

                // uint256[] memory colorMapping = attributes[i]
                //     .info[svgNumber]
                //     .range;

                for (
                    uint32 j = 0;
                    j < attributes[i].info[svgNumber].svg.length;
                    j++
                ) {
                    uint256 start = attributes[i].info[svgNumber].range[j][0];
                    uint256 end = attributes[i].info[svgNumber].range[j][1];
                    uint256 colorId = attributes[i].info[j].colorId;

                    if (end == 0) end = colors[colorId].count;

                    // if (female && i == 9) {
                    //     colorId++;
                    // }

                    // bytes memory color = colors[colorId].list[
                    //     (_seed + j) % colors[colorId].count
                    // ];
                    //colorsArray[j] = color;
                    if (foundAttribute) {
                        token.layers[count].colors[j] = colors[colorId].list[
                            randomNumber(
                                (_seed + (i * (j + 2)) + j),
                                [start, end]
                            )
                        ];
                    }
                }
                if (foundAttribute) {
                    token.layers[count].aId = i;
                    count = count + 1;
                }
            }
            token.revealed = true;
            token.count = count;
        }
    }

    // function revealArt(RevealToken calldata _revealToken)
    //     external
    //     onlyValidAccess(
    //         _revealToken.v,
    //         _revealToken.r,
    //         _revealToken.s,
    //         nonces[msg.sender],
    //         _revealToken.drop,
    //         _revealToken.index,
    //         msg.sender
    //     )
    // {
    //     TokenRevealInfo storage token = tokens[_revealToken.tokenId];
    //     require(_exists(_revealToken.tokenId), "Token does not exist");
    //     require(!token.revealed, "Token already revealed");

    //     unchecked {
    //         // this.generateTraits(token);
    //         uint256 _seed = block.timestamp + block.difficulty + block.number;

    //         token.seed = _seed;

    //         bool female;
    //         token.count = 12;

    //         //make new array of bytes

    //         //generate random traits here and store in token forloop 9 for basic traits

    //         for (uint32 i = 0; i < 13; i++) {
    //             uint256 svgNumber = _seed % svgList[i].count;
    //             uint256 varCount = svgLayers[i].attributes[svgNumber].varCount;

    //             //create new array of 9 empty

    //             if (i == 4 && svgNumber == 1) {
    //                 female = true;
    //                 token.count += 1;
    //             }

    //             if (!female && svgNumber == 12) break;

    //             uint256[] memory colorMapping = svgLayers[i]
    //                 .attributes[svgNumber]
    //                 .colorMapping;
    //             bytes[] memory colorsArray = new bytes[](varCount);
    //             for (uint32 j = 0; j < varCount; j++) {
    //                 uint256 colorId = svgLayers[i].attributes[j].colorId;

    //                 if (female && i == 7) {
    //                     colorId++;
    //                 }

    //                 bytes memory color = colors[colorId].list[
    //                     (_seed + j) % colors[colorId].count
    //                 ];
    //                 colorsArray[j] = color;

    //                 token.layers[i].colors[j] = colorsArray[colorMapping[j]];
    //             }
    //             token.revealed = true;
    //         }

    //         //  uint32[] memory layers = new uint32[](8);
    //         // token.layers = new uint32[](10);

    //         // layers[0] = 0;
    //         // layers[1] = 1;
    //         // layers[2] = 2;
    //         // layers[3] = 3;
    //         // layers[4] = 4;
    //         // layers[5] = 5;
    //         // layers[6] = 6;
    //         // layers[7] = 8;
    //         // layers[8] = 8;

    //         //loop and add 2,1,3,4 layers 1000 times to test size and reveal

    //         //token.layers = layers;

    //         //token.layer[0].colors = new uint32[](1);
    //     }
    // }

    function setFamiliarContract(address _familiarContract) public {
        familiarContract = AiAlbumFamiliar(_familiarContract);
    }

    function revealArtOnchain(uint256 _tokenId) external {
        TokenRevealInfo storage token = tokens[_tokenId];

        //check ownership

        require(
            ownerOf(_tokenId) == msg.sender ||
                mintIndex[_tokenId].owner == msg.sender,
            "Not owner"
        );

        require(!token.revealed, "Token already revealed");

        //first grab a number 1-4 to determine how many random traits there might be (Make 4 much less likely)

        uint256 _seed = block.timestamp + block.difficulty + block.number;
        uint256 traitCount = _seed % 5;
        uint8 extraTrait;
        uint256[] storage attributeIds;
        if (traitCount == 0 || traitCount == 4) {
            extraTrait = uint8(_seed % 70);

            if (extraTrait < 69) {
                traitCount = 4;
            } else if (extraTrait == 69) {
                traitCount = 0;
            }
        }

        if (traitCount > 0 && (_seed + traitCount) % 8 == 0) {
            attributeIds = attributeLayerGlasses;
            traitCount--;
        } else attributeIds = attributeLayerNoGlasses;

        if (traitCount > 0 && (_seed + traitCount) % 4 == 0) {
            attributeIds.push(12);
            traitCount--;
        }

        if (traitCount > 0 && (_seed + traitCount) % 3 == 0) {
            attributeIds.push(13);
            traitCount--;
        }

        bool female;

        for (uint32 i = 0; i < attributeIds.length; i++) {
            uint256 id = attributeIds[i];
            uint256 svgNumber = _seed % svgLayers[id].layerCount;

            // if (i == 6 || i == 12 || i == 13) {
            //     foundAttribute = false;
            // }

            //create new array of 9 empty

            // if (i == 6 && _seed % 4 == 0) {
            //     foundAttribute = true;
            // }

            if (id == 7 && svgNumber == 1) {
                female = true;
            }

            // if (i == 12 && _seed % 2 == 0) {
            //     foundAttribute = true;
            // }

            if (id == 13) {
                token.isMafia = true;
                // if ((_seed * 2) % 2 == 0) foundAttribute = true;
                // token.count += 1;
            }

            //attributes[i].info[svgNumber].colorId;

            // if (!female && svgNumber == 10) break;

            // uint256[] memory colorMapping = attributes[i]
            //     .info[svgNumber]
            //     .range;

            // if (attributes[id].info[svgNumber].svg.length == 1) {
            //     token.layers[i].colors[0] = "";
            // }

            for (
                uint32 j = 0;
                j < attributes[id].info[svgNumber].svg.length - 1;
                j++
            ) {
                uint256 colorId = attributes[id].info[j].colorId;
                // if (attributes[id].info[svgNumber].svg.length == 1) {
                //     token.layers[i].colors[j] = "";
                // } else {
                uint256 start = attributes[id].info[svgNumber].range[j][0];
                uint256 end = attributes[id].info[svgNumber].range[j][1];

                if (end == 0) end = colors[colorId].count;

                uint256 num = randomNumber(
                    (_seed + (i * (j + 2)) + j),
                    [start, end]
                );

                token.layers[i].colors[j] = colors[colorId].list[num];
                //}
            }

            token.layers[i].aId = id;
        }
        token.revealed = true;
        token.count = attributeIds.length;

        //now we need to loop through the traits and generate a random color for each one grabbing the
    }

    // function revealArt(RevealToken calldata _revealToken)
    //     external
    //     onlyValidAccess(
    //         _revealToken.v,
    //         _revealToken.r,
    //         _revealToken.s,
    //         nonces[msg.sender],
    //         _revealToken.drop,
    //         _revealToken.index,
    //         msg.sender
    //     )
    // {
    //     TokenRevealInfo storage token = tokens[_revealToken.tokenId];
    //     require(_exists(_revealToken.tokenId), "Token does not exist");
    //     require(!token.revealed, "Token already revealed");

    //     unchecked {
    //         // this.generateTraits(token);
    //         uint256 _seed = block.timestamp + block.difficulty + block.number;

    //         token.seed = _seed;

    //         bool female;
    //         token.count = 12;

    //         //make new array of bytes

    //         //generate random traits here and store in token forloop 9 for basic traits

    //         for (uint32 i = 0; i < 13; i++) {
    //             uint256 svgNumber = _seed % svgList[i].count;
    //             uint256 varCount = svgLayers[i].attributes[svgNumber].varCount;

    //             //create new array of 9 empty

    //             if (i == 4 && svgNumber == 1) {
    //                 female = true;
    //                 token.count += 1;
    //             }

    //             if (!female && svgNumber == 12) break;

    //             uint256[] memory colorMapping = svgLayers[i]
    //                 .attributes[svgNumber]
    //                 .colorMapping;
    //             bytes[] memory colorsArray = new bytes[](varCount);
    //             for (uint32 j = 0; j < varCount; j++) {
    //                 uint256 colorId = svgLayers[i].attributes[j].colorId;

    //                 if (female && i == 7) {
    //                     colorId++;
    //                 }

    //                 bytes memory color = colors[colorId].list[
    //                     (_seed + j) % colors[colorId].count
    //                 ];
    //                 colorsArray[j] = color;

    //                 token.layers[i].colors[j] = colorsArray[colorMapping[j]];
    //             }
    //             token.revealed = true;
    //         }

    //         //  uint32[] memory layers = new uint32[](8);
    //         // token.layers = new uint32[](10);

    //         // layers[0] = 0;
    //         // layers[1] = 1;
    //         // layers[2] = 2;
    //         // layers[3] = 3;
    //         // layers[4] = 4;
    //         // layers[5] = 5;
    //         // layers[6] = 6;
    //         // layers[7] = 8;
    //         // layers[8] = 8;

    //         //loop and add 2,1,3,4 layers 1000 times to test size and reveal

    //         //token.layers = layers;

    //         //token.layer[0].colors = new uint32[](1);
    //     }
    // }

    function generateDigits(uint256 _tokenId)
        public
        pure
        returns (uint8[] memory)
    {
        bytes memory digitsString = bytes(Strings.toString(_tokenId));
        uint8[] memory digits = new uint8[](digitsString.length);

        for (uint i = 0; i < digitsString.length; i++) {
            digits[i] = uint8(digitsString[i]) - 48;
        }

        return digits;
    }

    //TODO: create metadata system
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!tokens[_tokenId].revealed) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"Crypto-Mafia", "description":"An on-chain village or mafia member to join the game of crypto mafia.", "animation_url":"',
                                string(
                                    abi.encodePacked(
                                        baseURI,
                                        drops[0].ipfsPreview
                                    )
                                ),
                                '"}'
                            )
                        )
                    )
                );
        }

        // uint256 _seed = tokens[_tokenId].seed;

        // uint256 loopCount = tokens[_tokenId].layers.length;

        // //loop through count and generate svg
        // bytes memory _svg = abi.encodePacked(bgSvg[0], bgViewBox, bgSvg[1]);
        // for (uint256 i = 0; i < loopCount; i++) {
        //     uint32 layer = tokens[_tokenId].layers[i];
        //     _svg = abi.encodePacked(_svg, generateSVG(layer, _seed));
        // }

        // bytes memory _svg = abi.encodePacked(bgSvg[0], bgViewBox, bgSvg[1]);

        // uint32 layer = tokens[_tokenId].layers[0];

        bytes memory _attributes = abi.encodePacked(
            '"attributes":{"trait_type":"Mafia","value":"',
            tokens[_tokenId].isMafia ? "Yes" : "No",
            '"},'
        );

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name":"Crypto-Mafia", "description":"An on-chain village or mafia member to join the game of crypto mafia.",',
                _attributes,
                '"image":"data:image/svg+xml;base64,',
                Base64.encode(
                    this.recursiveGenerateSVG(
                        abi.encodePacked(bgSvg[0], bgViewBox, bgSvg[1]),
                        0,
                        _tokenId
                    )
                ),
                '"}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function recursiveGenerateSVG(
        bytes memory svgBytes,
        uint256 count,
        uint256 _tokenId
    ) external view returns (bytes memory) {
        uint256 id = tokens[_tokenId].layers[count].aId;

        uint256 _seed = tokens[_tokenId].seed;
        uint256 svgNumber = _seed % svgLayers[id].layerCount;

        uint32 oddFound = 0;

        //loop through string to create svg with required colors

        bytes memory newSvg = abi.encodePacked(
            attributes[id].info[svgNumber].svg[0]
        );

        //gnrat font info from id

        uint8[] memory tokenIdArray = generateDigits(_tokenId);

        bytes memory font = abi.encodePacked(
            '<text opacity=".4" fill="#1F2022" font-family="Mafia" x="1.5%" y="17%" font-size="16em" class="ls">#',
            Strings.toString(tokens[_tokenId].season)
        );

        for (uint256 i = 0; i < tokenIdArray.length; i++) {
            font = abi.encodePacked(
                font,
                '<tspan  x="',
                tokenIdArray[i] == 1 ? "6.5%" : "1.5%",
                '" dy=".865em">',
                Strings.toString(tokenIdArray[i]),
                "</tspan>"
            );
        }
        font = abi.encodePacked(font, "</text>");

        // string[3] private bgSvgGrad = [
        //     '<defs><linearGradient id="d" y2="1" x2="0"><stop stop-color="',
        //     '" offset="0"/><stop stop-color="',
        //     '" offset="1"/></linearGradient></defs><rect width="100%" height="100%" fill="url(#d)"/>'
        // ];

        for (
            uint256 i = 1;
            i < attributes[id].info[svgNumber].svg.length * 2 - 1;
            i++
        ) {
            //if odd then color is found
            if (i % 2 == 1) {
                //check if number or color
                if (attributes[id].info[svgNumber].isNumber[oddFound]) {
                    newSvg = abi.encodePacked(
                        newSvg,
                        Strings.toString(
                            randomNumber(
                                _seed,
                                attributes[id].info[svgNumber].range[oddFound]
                            )
                        )
                    );
                } else
                    newSvg = abi.encodePacked(
                        newSvg,
                        tokens[_tokenId].layers[count].colors[oddFound]
                    );
                oddFound++;
            } else {
                newSvg = abi.encodePacked(
                    newSvg,
                    attributes[id].info[svgNumber].svg[i - oddFound]
                );
            }
        }
        if (id != 0) {
            svgBytes = abi.encodePacked(
                svgBytes,
                svg[0],
                attributes[id].info[svgNumber].x,
                svg[1],
                attributes[id].info[svgNumber].y,
                svg[2],
                newSvg,
                svg[3]
            );
        } else {
            svgBytes = abi.encodePacked(svgBytes, newSvg, font);
        }

        if (count < tokens[_tokenId].count - 1) {
            return this.recursiveGenerateSVG(svgBytes, count + 1, _tokenId);
        } else return abi.encodePacked(svgBytes, "</svg>");
    }

    // function recursiveGenerateSVG(
    //         bytes memory svgBytes,
    //         uint32 id,
    //         uint256 _tokenId
    //     ) external view returns (bytes memory) {
    //         id = tokens[_tokenId].layers[id];
    //         uint256 _seed = tokens[_tokenId].seed;

    //         uint256 svgNumber = _seed % svgList[id].count;

    //         uint256 varCount = svgLayers[id].attributes[svgNumber].varCount;
    //         uint32 oddFound = 0;

    //         //loop through string to create svg with required colors

    //         bytes[] memory colorsArray = new bytes[](varCount);
    //         bytes memory newSvg = abi.encodePacked(
    //             svgList[id].layer[svgNumber].svg[0]
    //         );
    //         for (
    //             uint256 i = 1;
    //             i < svgList[id].layer[svgNumber].svg.length + varCount;
    //             i++
    //         ) {
    //             //if odd then color is found
    //             if (i % 2 == 1) {
    //                 colorsArray[oddFound] = colors[
    //                     svgLayers[id].attributes[svgNumber].colorId
    //                 ].list[
    //                         uint256(keccak256(abi.encodePacked(i, _seed))) %
    //                             colors[id].count
    //                     ];
    //                 newSvg = abi.encodePacked(
    //                     newSvg,
    //                     colorsArray[
    //                         svgLayers[id].attributes[svgNumber].colorMapping[
    //                             oddFound
    //                         ]
    //                     ]
    //                 );
    //                 oddFound++;
    //             } else {
    //                 newSvg = abi.encodePacked(
    //                     newSvg,
    //                     svgList[id].layer[svgNumber].svg[i - oddFound]
    //                 );
    //             }
    //         }
    //         if (id != 0) {
    //             svgBytes = abi.encodePacked(
    //                 svgBytes,
    //                 svg[0],
    //                 svgList[id].layer[svgNumber].x,
    //                 svg[1],
    //                 svgList[id].layer[svgNumber].y,
    //                 svg[2],
    //                 newSvg,
    //                 svg[3]
    //             );
    //         } else {
    //             svgBytes = abi.encodePacked(svgBytes, newSvg);
    //         }

    //         if (id < tokens[_tokenId].layers.length - 1) {
    //             return this.recursiveGenerateSVG(svgBytes, id + 1, _tokenId);
    //         } else return svgBytes;
    //     }

    function mintFamiliar(uint256 _tokenId) public {
        address mintAddress = stakingAddress();

        if (ownerOf(_tokenId) == msg.sender) {
            mintAddress = msg.sender;
        } else if (mintIndex[_tokenId].owner != msg.sender) {
            revert("Not Owner");
        }

        require(familiarUnlocked[_tokenId] == 0, "Already unlocked");

        familiarUnlocked[_tokenId] = familiarContract.totalSupply() + 1;

        familiarContract.mintFamiliar(mintAddress);
    }

    function _setStakeTimestamp(uint256 tokenId_, uint256 timestamp_)
        internal
        override
        returns (address)
    {
        // First, call _getTokenDataOf and grab the relevant tokenData
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        address _owner = _OwnerStruct.owner;
        uint32 _stakeTimestamp = _OwnerStruct.stakeTimestamp;

        // _setStakeTimestamp requires initialization
        _initializeTokenIf(tokenId_, _OwnerStruct);

        // Clear any token approvals
        delete getApproved[tokenId_];

        // if timestamp_ > 0, the action is "stake"
        if (timestamp_ > 0) {
            // Make sure that the token is not staked already
            require(
                _stakeTimestamp == 0,
                "ERC721G: _setStakeTimestamp() already staked"
            );

            // Callbrate balances between staker and stakingAddress
            unchecked {
                _balanceData[_owner].balance--;
                _balanceData[stakingAddress()].balance++;
            }
            //check if familier exist and if so, transfer it to staking address

            if (familiarUnlocked[tokenId_] != 0) {
                familiarContract.transferFrom(
                    msg.sender,
                    stakingAddress(),
                    familiarUnlocked[tokenId_]
                );
            }

            //  safeTransferFrom(_owner, stakingAddress(), tokenId_);

            // Emit Transfer event from trueOwner
            emit Transfer(_owner, stakingAddress(), tokenId_);
        }
        // if timestamp_ == 0, the action is "unstake"
        else {
            // Make sure the token is not staked
            require(
                _stakeTimestamp != 0,
                "ERC721G: _setStakeTimestamp() already unstaked"
            );

            // Callibrate balances between stakingAddress and staker
            unchecked {
                _balanceData[_owner].balance++;
                _balanceData[stakingAddress()].balance--;
            }

            // we add total time staked to the token on unstake
            uint32 _timeStaked = _getBlockTimestampCompressed() -
                _stakeTimestamp;
            _tokenData[tokenId_].totalTimeStaked += _timeStaked;

            if (familiarUnlocked[tokenId_] != 0) {
                familiarContract.transferFrom(
                    stakingAddress(),
                    msg.sender,
                    familiarUnlocked[tokenId_]
                );
            }

            // Emit Transfer event to trueOwner
            emit Transfer(stakingAddress(), _owner, tokenId_);
        }

        // Set the stakeTimestamp to timestamp_
        _tokenData[tokenId_].stakeTimestamp = _compressTimestamp(timestamp_);

        // We save internal gas by returning the owner for a follow-up function
        return _owner;
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId_),
            "ERC721G: transferFrom unauthorized"
        );

        if (familiarUnlocked[tokenId_] != 0) {
            familiarContract.transferFrom(from_, to_, tokenId_);
        }
        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override {
        require(
            _isApprovedOrOwner(msg.sender, tokenId_),
            "ERC721G: transferFrom unauthorized"
        );

        if (familiarUnlocked[tokenId_] != 0) {
            familiarContract.safeTransferFrom(
                from_,
                to_,
                familiarUnlocked[tokenId_]
            );
        }
        _transfer(from_, to_, tokenId_);
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
pragma solidity ^0.8.15;

//////////////////////////////////////////////
//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★//
//★    _______  _____  _______ ___  _____  ★//
//★   / __/ _ \/ ___/ /_  /_  <  / / ___/  ★//
//★  / _// , _/ /__    / / __// / / (_ /   ★//
//★ /___/_/|_|\___/   /_/____/_/  \___/    ★//
//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★//
//  by: 0xInuarashi                         //
//////////////////////////////////////////////
//  Audits: 0xAkihiko, 0xFoobar             //
//////////////////////////////////////////////
//  Default: Staking Disabled               //
//////////////////////////////////////////////

contract ERC721G {
    // Standard ERC721 Events
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    // Standard ERC721 Global Variables
    string public name; // Token Name
    string public symbol; // Token Symbol

    // ERC721G Global Variables
    uint256 public tokenIndex; // The running index for the next TokenId
    uint256 public immutable startTokenId; // Bytes Storage for the starting TokenId
    uint256 public immutable maxBatchSize;

    // ERC721G Staking Address Target
    function stakingAddress() public view returns (address) {
        return address(this);
    }

    /** @dev instructions:
     *  name_ sets the token name
     *  symbol_ sets the token symbol
     *  startId_ sets the starting tokenId (recommended 0-1)
     *  maxBatchSize_ sets the maximum batch size for each mint (recommended 5-20)
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 startId_,
        uint256 maxBatchSize_
    ) {
        name = name_;
        symbol = symbol_;
        tokenIndex = startId_;
        startTokenId = startId_;
        maxBatchSize = maxBatchSize_;
    }

    // ERC721G Structs
    struct OwnerStruct {
        address owner; // stores owner address for OwnerOf
        uint32 lastTransfer; // stores the last transfer of the token
        uint32 stakeTimestamp; // stores the stake timestamp in _setStakeTimestamp()
        uint32 totalTimeStaked; // stores the total time staked accumulated
    }

    struct BalanceStruct {
        uint32 balance; // stores the token balance of the address
        uint32 mintedAmount; // stores the minted amount of the address on mint
        // 24 Free Bytes
    }

    // ERC721G Mappings
    mapping(uint256 => OwnerStruct) public _tokenData; // ownerOf replacement
    mapping(address => BalanceStruct) public _balanceData; // balanceOf replacement
    mapping(uint256 => OwnerStruct) public mintIndex; // uninitialized ownerOf pointer

    // ERC721 Mappings
    mapping(uint256 => address) public getApproved; // for single token approvals
    mapping(address => mapping(address => bool)) public isApprovedForAll; // approveall

    // Time Expansion and Compression by 0xInuarashi
    /** @dev Time Expansion and Compression extends the usage of ERC721G from
     *  Year 2106 (end of uint32) to Year 3331 (end of uint32 with time expansion)
     *  the trade-off is that staking accuracy is scoped within 10-second chunks
     */
    function _getBlockTimestampCompressed()
        public
        view
        virtual
        returns (uint32)
    {
        return uint32(block.timestamp / 10);
    }

    function _compressTimestamp(uint256 timestamp_)
        public
        view
        virtual
        returns (uint32)
    {
        return uint32(timestamp_ / 10);
    }

    function _expandTimestamp(uint32 timestamp_)
        public
        view
        virtual
        returns (uint256)
    {
        return uint256(timestamp_) * 10;
    }

    function getLastTransfer(uint256 tokenId_)
        public
        view
        virtual
        returns (uint256)
    {
        return _expandTimestamp(_getTokenDataOf(tokenId_).lastTransfer);
    }

    function getStakeTimestamp(uint256 tokenId_)
        public
        view
        virtual
        returns (uint256)
    {
        return _expandTimestamp(_getTokenDataOf(tokenId_).stakeTimestamp);
    }

    function getTotalTimeStaked(uint256 tokenId_)
        public
        view
        virtual
        returns (uint256)
    {
        return _expandTimestamp(_getTokenDataOf(tokenId_).totalTimeStaked);
    }

    ///// ERC721G: ERC721-Like Simple Read Outputs /////
    function totalSupply() public view virtual returns (uint256) {
        return tokenIndex - startTokenId;
    }

    function balanceOf(address address_) public view virtual returns (uint256) {
        return _balanceData[address_].balance;
    }

    ///// ERC721G: Range-Based Logic /////

    /** @dev explanation:
     *  _getTokenDataOf() finds and returns either the (and in priority)
     *      - the initialized storage pointer from _tokenData
     *      - the uninitialized storage pointer from mintIndex
     *
     *  if the _tokenData storage slot is populated, return it
     *  otherwise, do a reverse-lookup to find the uninitialized pointer from mintIndex
     */
    function _getTokenDataOf(uint256 tokenId_)
        public
        view
        virtual
        returns (OwnerStruct memory)
    {
        // The tokenId must be above startTokenId only
        require(tokenId_ >= startTokenId, "TokenId below starting Id!");

        // If the _tokenData is initialized (not 0x0), return the _tokenData
        if (
            _tokenData[tokenId_].owner != address(0) || tokenId_ >= tokenIndex
        ) {
            return _tokenData[tokenId_];
        }
        // Else, do a reverse-lookup to find  the corresponding uninitialized pointer
        else {
            unchecked {
                uint256 _lowerRange = tokenId_;
                while (mintIndex[_lowerRange].owner == address(0)) {
                    _lowerRange--;
                }
                return mintIndex[_lowerRange];
            }
        }
    }

    /** @dev explanation:
     *  ownerOf calls _getTokenDataOf() which returns either the initialized or
     *  uninitialized pointer.
     *  Then, it checks if the token is staked or not through stakeTimestamp.
     *  If the token is staked, return the stakingAddress, otherwise, return the owner.
     */
    function ownerOf(uint256 tokenId_) public view virtual returns (address) {
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        return
            _OwnerStruct.stakeTimestamp == 0
                ? _OwnerStruct.owner
                : stakingAddress();
    }

    /** @dev explanation:
     *  _trueOwnerOf() calls _getTokenDataOf() which returns either the initialized or
     *  uninitialized pointer.
     *  It returns the owner directly without any checks.
     *  Used internally for proving the staker address on unstake.
     */
    function _trueOwnerOf(uint256 tokenId_)
        public
        view
        virtual
        returns (address)
    {
        return _getTokenDataOf(tokenId_).owner;
    }

    ///// ERC721G: Internal Single-Contract Staking Logic /////

    /** @dev explanation:
     *  _initializeTokenIf() is used as a beginning-hook to functions that require
     *  that the token is explicitly INITIALIZED before the function is able to be used.
     *  It will check if the _tokenData slot is initialized or not.
     *  If it is not, it will initialize it.
     *  Used internally for staking logic.
     */
    function _initializeTokenIf(
        uint256 tokenId_,
        OwnerStruct memory _OwnerStruct
    ) internal virtual {
        // If the target _tokenData is not initialized, initialize it.
        if (_tokenData[tokenId_].owner == address(0)) {
            _tokenData[tokenId_] = _OwnerStruct;
        }
    }

    /** @dev explanation:
     *  _setStakeTimestamp() is our staking / unstaking logic.
     *  If timestamp_ is > 0, the action is "stake"
     *  If timestamp_ is == 0, the action is "unstake"
     *
     *  We grab the tokenData using _getTokenDataOf and then read its values.
     *  As this function requires INITIALIZED tokens only, we call _initializeTokenIf()
     *  to initialize any token using this function first.
     *
     *  Processing of the function is explained in in-line comments.
     */
    function _setStakeTimestamp(uint256 tokenId_, uint256 timestamp_)
        internal
        virtual
        returns (address)
    {
        // First, call _getTokenDataOf and grab the relevant tokenData
        OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
        address _owner = _OwnerStruct.owner;
        uint32 _stakeTimestamp = _OwnerStruct.stakeTimestamp;

        // _setStakeTimestamp requires initialization
        _initializeTokenIf(tokenId_, _OwnerStruct);

        // Clear any token approvals
        delete getApproved[tokenId_];

        // if timestamp_ > 0, the action is "stake"
        if (timestamp_ > 0) {
            // Make sure that the token is not staked already
            require(
                _stakeTimestamp == 0,
                "ERC721G: _setStakeTimestamp() already staked"
            );

            // Callbrate balances between staker and stakingAddress
            unchecked {
                _balanceData[_owner].balance--;
                _balanceData[stakingAddress()].balance++;
            }
            //check if familier exist and if so, transfer it to staking address

            // Emit Transfer event from trueOwner
            emit Transfer(_owner, stakingAddress(), tokenId_);
        }
        // if timestamp_ == 0, the action is "unstake"
        else {
            // Make sure the token is not staked
            require(
                _stakeTimestamp != 0,
                "ERC721G: _setStakeTimestamp() already unstaked"
            );

            // Callibrate balances between stakingAddress and staker
            unchecked {
                _balanceData[_owner].balance++;
                _balanceData[stakingAddress()].balance--;
            }

            // we add total time staked to the token on unstake
            uint32 _timeStaked = _getBlockTimestampCompressed() -
                _stakeTimestamp;
            _tokenData[tokenId_].totalTimeStaked += _timeStaked;

            // Emit Transfer event to trueOwner
            emit Transfer(stakingAddress(), _owner, tokenId_);
        }

        // Set the stakeTimestamp to timestamp_
        _tokenData[tokenId_].stakeTimestamp = _compressTimestamp(timestamp_);

        // We save internal gas by returning the owner for a follow-up function
        return _owner;
    }

    /** @dev explanation:
     *  _stake() works like an extended function of _setStakeTimestamp()
     *  where the logic of _setStakeTimestamp() runs and returns the _owner address
     *  afterwards, we do the post-hook required processing to finish the staking logic
     *  in this function.
     *
     *  Processing logic explained in in-line comments.
     */
    function _stake(uint256 tokenId_) internal virtual returns (address) {
        // set the stakeTimestamp to block.timestamp and return the owner
        return _setStakeTimestamp(tokenId_, block.timestamp);
    }

    /** @dev explanation:
     *  _unstake() works like an extended unction of _setStakeTimestamp()
     *  where the logic of _setStakeTimestamp() runs and returns the _owner address
     *  afterwards, we do the post-hook required processing to finish the unstaking logic
     *  in this function.
     *
     *  Processing logic explained in in-line comments.
     */
    function _unstake(uint256 tokenId_) internal virtual returns (address) {
        // set the stakeTimestamp to 0 and return the owner
        return _setStakeTimestamp(tokenId_, 0);
    }

    /** @dev explanation:
     *  _mintAndStakeInternal() is the internal mintAndStake function that is called
     *  to mintAndStake tokens to users.
     *
     *  It populates mintIndex with the phantom-mint data (owner, lastTransferTime)
     *  as well as the phantom-stake data (stakeTimestamp)
     *
     *  Then, it emits the necessary phantom events to replicate the behavior as canon.
     *
     *  Further logic explained in in-line comments.
     */
    function _mintAndStakeInternal(address to_, uint256 amount_)
        internal
        virtual
    {
        // we cannot mint to 0x0
        require(to_ != address(0), "ERC721G: _mintAndStakeInternal to 0x0");

        // we limit max mints per SSTORE to prevent expensive gas lookup
        require(
            amount_ <= maxBatchSize,
            "ERC721G: _mintAndStakeInternal over maxBatchSize"
        );

        // process the required variables to write to mintIndex
        uint256 _startId = tokenIndex;
        uint256 _endId = _startId + amount_;
        uint32 _currentTime = _getBlockTimestampCompressed();

        // write to the mintIndex to store the OwnerStruct for uninitialized tokenData
        mintIndex[_startId] = OwnerStruct(
            to_, // the address the token is minted to
            _currentTime, // the last transfer time
            _currentTime, // the curent time of staking
            0 // the accumulated time staked
        );

        unchecked {
            // we add the balance to the stakingAddress through our staking logic
            _balanceData[stakingAddress()].balance += uint32(amount_);

            // we add the mintedAmount to the to_ through our minting logic
            _balanceData[to_].mintedAmount += uint32(amount_);

            // emit phantom mint to to_, then emit a staking transfer
            do {
                emit Transfer(address(0), to_, _startId);
                emit Transfer(to_, stakingAddress(), _startId);
            } while (++_startId < _endId);
        }

        // set the new tokenIndex to the _endId
        tokenIndex = _endId;
    }

    /** @dev explanation:
     *  _mintAndStake() calls _mintAndStakeInternal() but calls it using a while-loop
     *  based on the required minting amount to stay within the bounds of
     *  max mints per batch (maxBatchSize)
     */
    function _mintAndStake(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintAndStakeInternal(to_, maxBatchSize);
        }
        _mintAndStakeInternal(to_, _amountToMint);
    }

    ///// ERC721G Range-Based Internal Minting Logic /////

    /** @dev explanation:
     *  _mintInternal() is our internal batch minting logic.
     *  First, we store the uninitialized pointer at mintIndex of _startId
     *  Then, we process the balances changes
     *  Finally, we phantom-mint the tokens using Transfer events loop.
     */
    function _mintInternal(address to_, uint256 amount_) internal virtual {
        // cannot mint to 0x0
        require(to_ != address(0), "ERC721G: _mintInternal to 0x0");

        // we limit max mints to prevent expensive gas lookup
        require(
            amount_ <= maxBatchSize,
            "ERC721G: _mintInternal over maxBatchSize"
        );

        // process the token id data
        uint256 _startId = tokenIndex;
        uint256 _endId = _startId + amount_;

        // push the required phantom mint data to mintIndex
        mintIndex[_startId].owner = to_;
        mintIndex[_startId].lastTransfer = _getBlockTimestampCompressed();

        // process the balance changes and do a loop to phantom-mint the tokens to to_
        unchecked {
            _balanceData[to_].balance += uint32(amount_);
            _balanceData[to_].mintedAmount += uint32(amount_);

            do {
                emit Transfer(address(0), to_, _startId);
            } while (++_startId < _endId);
        }

        // set the new token index
        tokenIndex = _endId;
    }

    /** @dev explanation:
     *  _mint() is the function that calls _mintInternal() using a while-loop
     *  based on the maximum batch size (maxBatchSize)
     */
    function _mint(address to_, uint256 amount_) internal virtual {
        uint256 _amountToMint = amount_;
        while (_amountToMint > maxBatchSize) {
            _amountToMint -= maxBatchSize;
            _mintInternal(to_, maxBatchSize);
        }
        _mintInternal(to_, _amountToMint);
    }

    /** @dev explanation:
     *  _transfer() is the internal function that transfers the token from_ to to_
     *  it has ERC721-standard require checks
     *  and then uses solmate-style approval clearing
     *
     *  afterwards, it sets the _tokenData to the data of the to_ (transferee) as well as
     *  set the balanceData.
     *
     *  this results in INITIALIZATION of the token, if it has not been initialized yet.
     */
    function _transfer(
        address from_,
        address to_,
        uint256 tokenId_
    ) internal virtual {
        // the from_ address must be the ownerOf
        require(from_ == ownerOf(tokenId_), "ERC721G: _transfer != ownerOf");
        // cannot transfer to 0x0
        require(to_ != address(0), "ERC721G: _transfer to 0x0");

        // delete any approvals
        delete getApproved[tokenId_];

        // set _tokenData to to_
        _tokenData[tokenId_].owner = to_;
        _tokenData[tokenId_].lastTransfer = _getBlockTimestampCompressed();

        // update the balance data
        unchecked {
            _balanceData[from_].balance--;
            _balanceData[to_].balance++;
        }

        // emit a standard Transfer
        emit Transfer(from_, to_, tokenId_);
    }

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: User-Enabled Out-of-the-box Staking Functionality /////
    ///// Note: You may implement your own staking functionality     /////
    /////       by using _stake() and _unstake() functions instead   /////
    /////       These are merely out-of-the-box standard functions   /////
    //////////////////////////////////////////////////////////////////////
    // /** @dev clarification:
    //  *  As a developer, you DO NOT have to enable these functions, or use them
    //  *  in the way defined in this section.
    //  *
    //  *  The functions in this section are just out-of-the-box plug-and-play staking
    //  *  which is enabled IMMEDIATELY.
    //  *  (As well as some useful view-functions)
    //  *
    //  *  You can choose to call the internal staking functions yourself, to create
    //  *  custom staking logic based on the section (n-2) above.
    //  */
    // /** @dev explanation:
    // *  this is a staking function that receives calldata tokenIds_ array
    // *  and loops to call internal _stake in a gas-efficient way
    // *  written in a shorthand-style syntax
    // */
    function stake(uint256[] calldata tokenIds_) public virtual {
        uint256 i;
        uint256 l = tokenIds_.length;
        while (i < l) {
            // stake and return the owner's address
            address _owner = _stake(tokenIds_[i]);
            // make sure the msg.sender is the owner
            require(msg.sender == _owner, "You are not the owner!");
            unchecked {
                ++i;
            }
        }
    }

    // /** @dev explanation:
    // *  this is an unstaking function that receives calldata tokenIds_ array
    // *  and loops to call internal _unstake in a gas-efficient way
    // *  written in a shorthand-style syntax
    // */
    function unstake(uint256[] calldata tokenIds_) public virtual {
        uint256 i;
        uint256 l = tokenIds_.length;
        while (i < l) {
            // unstake and return the owner's address
            address _owner = _unstake(tokenIds_[i]);
            // make sure the msg.sender is the owner
            require(msg.sender == _owner, "You are not the owner!");
            unchecked {
                ++i;
            }
        }
    }

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: User-Enabled Out-of-the-box Staking Functionality /////
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    /////      ERC721G: User-Enabled Staking Helper Functions        /////
    /////      Note: You MUST enable staking functionality           /////
    /////            To make use of these functions below            /////
    //////////////////////////////////////////////////////////////////////
    // /** @dev explanation:
    //  *  balanceOfStaked loops through the entire tokens using
    //  *  startTokenId as the start pointer, and
    //  *  tokenIndex (current-next tokenId) as the end pointer
    //  *
    //  *  it checks if the _trueOwnerOf() is the address_ or not
    //  *  and if the owner() is not the address, indicating the
    //  *  state that the token is staked.
    //  *
    //  *  if so, it increases the balance. after the loop, it returns the balance.
    //  *
    //  *  this is mainly for external view only.
    //  *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
    //  */
    function balanceOfStaked(address address_)
        public
        view
        virtual
        returns (uint256)
    {
        uint256 _balance;
        uint256 i = startTokenId;
        uint256 max = tokenIndex;
        while (i < max) {
            if (ownerOf(i) != address_ && _trueOwnerOf(i) == address_) {
                _balance++;
            }
            unchecked {
                ++i;
            }
        }
        return _balance;
    }

    // /** @dev explanation:
    //  *  walletOfOwnerStaked calls balanceOfStaked to get the staked
    //  *  balance of a user. Afterwards, it runs staked-checking logic
    //  *  to figure out the tokenIds that the user has staked
    //  *  and then returns it in walletOfOwner fashion.
    //  *
    //  *  this is mainly for external view only.
    //  *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
    //  */
    function walletOfOwnerStaked(address address_)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOfStaked(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _currentIndex;
        uint256 i = startTokenId;
        while (_currentIndex < _balance) {
            if (ownerOf(i) != address_ && _trueOwnerOf(i) == address_) {
                _tokens[_currentIndex++] = i;
            }
            unchecked {
                ++i;
            }
        }
        return _tokens;
    }

    // /** @dev explanation:
    //  *  balanceOf of the address returns UNSTAKED tokens only.
    //  *  to get the total balance of the user containing both STAKED and UNSTAKED tokens,
    //  *  we use this function.
    //  *
    //  *  this is mainly for external view only.
    //  *  !! NOT TO BE INTERFACED WITH CONTRACT WRITE FUNCTIONS EVER.
    //  */
    // function totalBalanceOf(address address_) public virtual view returns (uint256) {
    //     return balanceOf(address_) + balanceOfStaked(address_);
    // }
    // /** @dev explanation:
    //  *  totalTimeStakedOfToken returns the accumulative total time staked of a tokenId
    //  *  it reads from the totalTimeStaked of the tokenId_ and adds it with
    //  *  a calculation of pending time staked and returns the sum of both values.
    //  *
    //  *  this is mainly for external view / use only.
    //  *  this function can be interfaced with contract writes.
    //  */
    // function totalTimeStakedOfToken(uint256 tokenId_) public virtual view
    // returns (uint256) {
    //     OwnerStruct memory _OwnerStruct = _getTokenDataOf(tokenId_);
    //     uint256 _totalTimeStakedOnToken = _expandTimestamp(_OwnerStruct.totalTimeStaked);
    //     uint256 _totalTimeStakedPending =
    //         _OwnerStruct.stakeTimestamp > 0 ?
    //         _expandTimestamp(
    //             _getBlockTimestampCompressed() - _OwnerStruct.stakeTimestamp) :
    //             0;
    //     return _totalTimeStakedOnToken + _totalTimeStakedPending;
    // }
    // /** @dev explanation:
    //  *  totalTimeStakedOfTokens just returns an array of totalTimeStakedOfToken
    //  *  based on tokenIds_ calldata.
    //  *
    //  *  this is mainly for external view / use only.
    //  *  this function can be interfaced with contract writes... however
    //  *  BE CAREFUL and USE IT CORRECTLY.
    //  *  (dont pass in 5000 tokenIds_ in a write function)
    //  */
    // function totalTimeStakedOfTokens(uint256[] calldata tokenIds_) public
    // virtual view returns (uint256[] memory) {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     uint256[] memory _totalTimeStakeds = new uint256[] (l);
    //     while (i < l) {
    //         _totalTimeStakeds[i] = totalTimeStakedOfToken(tokenIds_[i]);
    //         unchecked { ++i; }
    //     }
    //     return _totalTimeStakeds;
    // }
    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: User-Enabled Staking Helper Functions             /////
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: Optional Additional Helper Functions              /////
    ///// Note: You do not need to enable these. It makes querying   /////
    /////       things cheaper in GAS at around 1.5k per token       /////
    ////        if you choose to query things as such                /////
    //////////////////////////////////////////////////////////////////////
    // /** @dev description: You can pass an array of <tokenIds_> here
    //  *  in order to query if all the <tokenIds_> passed is owned by
    //  *  the address <owner> (using ownerOf())
    //  *  doing so saves around 1.5k gas of external contract call gas
    //  *  per token which scales linearly in batch queries
    //  */
    // function isOwnerOfAll(address owner, uint256[] calldata tokenIds_)
    // external view returns (bool) {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     unchecked { do {
    //         if (ownerOf(tokenIds_[i]) != owner) return false;
    //     } while (++i < l); }
    //     return true;
    // }
    // /** @dev description: You can pass an array of <tokenIds_> here
    //  *  in order to query if all the <tokenIds_> passed is owned by
    //  *  the address <owner> (using _trueOwnerOf())
    //  *  doing so saves around 1.5k gas of external contract call gas
    //  *  per token which scales linearly in batch queries
    //  */
    // function isTrueOwnerOfAll(address owner, uint256[] calldata tokenIds_)
    // external view returns (bool) {
    //     uint256 i;
    //     uint256 l = tokenIds_.length;
    //     unchecked { do {
    //         if (_trueOwnerOf(tokenIds_[i]) != owner) return false;
    //     } while (++i < l); }
    //     return true;
    // }
    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: Optional Additional Helper Functions              /////
    //////////////////////////////////////////////////////////////////////

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: ERC721 Standard Logic                             /////
    //////////////////////////////////////////////////////////////////////
    /** @dev clarification:
     *  no explanations here as these are standard ERC721 logics.
     *  the reason that we can use standard ERC721 logics is because
     *  the ERC721G logic is compartmentalized and supports internally
     *  these ERC721 logics without any need of modification.
     */
    function _isApprovedOrOwner(address spender_, uint256 tokenId_)
        internal
        view
        virtual
        returns (bool)
    {
        address _owner = ownerOf(tokenId_);
        return (// "i am the owner of the token, and i am transferring it"
        _owner == spender_ ||
            // "the token's approved spender is me"
            getApproved[tokenId_] == spender_ ||
            // "the owner has approved me to spend all his tokens"
            isApprovedForAll[_owner][spender_]);
    }

    /** @dev clarification:
     *  sets a specific address to be able to spend a specific token.
     */
    function _approve(address to_, uint256 tokenId_) internal virtual {
        getApproved[tokenId_] = to_;
        emit Approval(ownerOf(tokenId_), to_, tokenId_);
    }

    function approve(address to_, uint256 tokenId_) public virtual {
        address _owner = ownerOf(tokenId_);
        require(
            // "i am the owner, and i am approving this token."
            _owner == msg.sender ||
                // "i am isApprovedForAll, so i can approve this token too."
                isApprovedForAll[_owner][msg.sender],
            "ERC721G: approve not authorized"
        );

        _approve(to_, tokenId_);
    }

    function _setApprovalForAll(
        address owner_,
        address operator_,
        bool approved_
    ) internal virtual {
        isApprovedForAll[owner_][operator_] = approved_;
        emit ApprovalForAll(owner_, operator_, approved_);
    }

    function setApprovalForAll(address operator_, bool approved_)
        public
        virtual
    {
        // this function can only be used as self-approvalforall for others.
        _setApprovalForAll(msg.sender, operator_, approved_);
    }

    function _exists(uint256 tokenId_) internal view virtual returns (bool) {
        return ownerOf(tokenId_) != address(0);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual {
        require(
            _isApprovedOrOwner(msg.sender, tokenId_),
            "ERC721G: transferFrom unauthorized"
        );
        _transfer(from_, to_, tokenId_);
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_,
        bytes memory data_
    ) public virtual {
        transferFrom(from_, to_, tokenId_);
        if (to_.code.length != 0) {
            (, bytes memory _returned) = to_.call(
                abi.encodeWithSelector(
                    0x150b7a02,
                    msg.sender,
                    from_,
                    tokenId_,
                    data_
                )
            );
            bytes4 _selector = abi.decode(_returned, (bytes4));
            require(
                _selector == 0x150b7a02,
                "ERC721G: safeTransferFrom to_ non-ERC721Receivable!"
            );
        }
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public virtual {
        safeTransferFrom(from_, to_, tokenId_, "");
    }

    function supportsInterface(bytes4 iid_) public view virtual returns (bool) {
        return
            iid_ == 0x01ffc9a7 ||
            iid_ == 0x80ac58cd ||
            iid_ == 0x5b5e139f ||
            iid_ == 0x7f5828d0;
    }

    /** @dev description: walletOfOwner to query an array of wallet's
     *  owned tokens. A view-intensive alternative ERC721Enumerable function.
     */
    function walletOfOwner(address address_)
        public
        view
        virtual
        returns (uint256[] memory)
    {
        uint256 _balance = balanceOf(address_);
        uint256[] memory _tokens = new uint256[](_balance);
        uint256 _currentIndex;
        uint256 i = startTokenId;
        while (_currentIndex < _balance) {
            if (ownerOf(i) == address_) {
                _tokens[_currentIndex++] = i;
            }
            unchecked {
                ++i;
            }
        }
        return _tokens;
    }

    //////////////////////////////////////////////////////////////////////
    ///// ERC721G: ERC721 Standard Logic                             /////
    //////////////////////////////////////////////////////////////////////

    /** @dev requirement: You MUST implement your own tokenURI logic here
     *  recommended to use through an override function in your main contract.
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        returns (string memory)
    {}
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
//import "./ERC721G.sol";
import "./ERC721C.sol";

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

//species, eyes, nose, mouth, background, accessories, accesoriesCount, first Name, last Name, sex,

contract AiAlbumFamiliar is ERC721C, Ownable, ReentrancyGuard {
    address private NEO;
    bytes public baseURI = "https://oca.mypinata.cloud/ipfs/";

    uint256 public totalSupply = 0;

    address private The_Dude = 0xC4741484290Ec4673c6e6Ca2d1b255e7749bB82b;

    uint8 bgTypeCount = 2;
    uint8 eyesCount = 1;
    uint8 eyeColorCount = 10;
    uint8 gradientColorCount = 22;
    uint8 speciesCount = 4;
    uint8 speciesColorCount = 5;
    uint256 lastTokenId;

    string bgViewBox = "0 0 1280 1280";

    //     bgSvg[0],
    // c1,
    // bgSvg[1],
    // c2,
    // bgSvg[2],
    // generateHead(),
    // bgSvg[3]

    //        uint256 svgId;
    //    uint256 colorId;
    //    uint256 varCount;

    //        colorMapping2[0] = 0;
    // svgLayers[_id].attributes[listId] = SVGAttributes(
    //     1,
    //     0,
    //     1,
    //     colorMapping2
    // );

    struct AddAttribute {
        uint32 id;
        string[] svg;
        uint256[] colorMapping;
    }

    struct TokenLayers {
        uint256[] attributes;
        uint256 aId;
        mapping(uint256 => bytes) colors;
    }

    struct TokenRevealInfo {
        bool isMafia;
        bool revealed;
        uint256 seed;
        uint256 season;
        uint256 count;
        mapping(uint256 => TokenLayers) layers;
    }
    struct TokenLayerInfo {
        uint32 layer;
    }

    struct Eyes {
        mapping(uint256 => bytes32) name;
        mapping(uint256 => bytes) eyeColors;
    }

    struct Drops {
        bytes ipfsHash;
        bytes ipfsPreview;
        uint16 id;
        uint16 revealStage;
        uint256 snapshot;
    }

    struct Backgrounds {
        mapping(uint256 => bytes32) backgroundType;
        mapping(uint256 => bytes) gradientColors;
    }

    struct Species {
        mapping(uint256 => bytes32) name;
        mapping(uint256 => bytes) speciesColors;
    }

    Backgrounds private backgrounds;
    Species private species;
    Eyes private eyes;

    struct GradientBGs {
        bytes color;
    }

    // struct DropInfo {
    //     uint16 id;
    //     uint256 snapshot;
    //     uint256 baseIPFS;
    //     uint256 previewIPFS;
    //     mapping(uint256 => HashInfo) hashes;
    // }

    struct TokenInfo {
        uint16 stage;
        uint256 lastToken;
        uint256 hash;
    }

    struct RevealToken {
        uint8 v;
        uint256 drop;
        uint256 index;
        bytes32 r;
        bytes32 s;
        uint256 tokenId;
    }

    struct SVGInfo {
        bytes name;
        uint256 count;
        mapping(uint256 => SVGLayer) layer;
    }

    struct SVGLayer {
        bool inactive;
        uint256 remaining;
        string x;
        string y;
        string[] svg;
    }

    struct SVGLayers {
        bytes name;
        uint256 layerCount;
        mapping(uint256 => SVGAttributes) attributes;
    }

    struct Colors {
        bytes name;
        uint256 count;
        mapping(uint256 => bytes) list;
    }

    struct SVGAttributes {
        uint256 svgId;
        uint256 colorId;
        uint256 varCount;
        uint256[] colorMapping;
    }

    struct AttributeMapping {
        bytes name;
        uint256 attributeCount;
        mapping(uint256 => Attribute) info;
    }

    struct Attribute {
        mapping(uint256 => bool) isNumber;
        mapping(uint256 => uint256[2]) range;
        bool inactive;
        uint256 remaining;
        uint256 colorId;
        uint256 varCount;
        string x;
        string y;
        string[] svg;
    }

    struct Accessories {
        uint256 position;
        uint256 id;
    }

    mapping(uint256 => Accessories) public accessories;

    //     struct SVGInfo {
    //     bytes name;
    //     uint256 count;
    //     mapping(uint256 => SVGLayer) layer;
    // }

    // struct SVGLayer {
    //     bool inactive;
    //     uint256 remaining;
    //     string x;
    //     string y;
    //     string[] svg;
    // }

    // mapping(uint32 => SVGInfo) private svgList;

    mapping(address => uint256) public nonces;
    mapping(uint256 => Drops) private drops;
    mapping(uint256 => TokenRevealInfo) public tokens;

    mapping(uint256 => Colors) private colors;
    mapping(uint256 => SVGLayers) public svgLayers;

    mapping(uint256 => AttributeMapping) public attributes;

    mapping(uint256 => bool) public tokenLayers;

    uint256[] attributeLayerGlasses = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
    uint256[] attributeLayerNoGlasses = [0, 1, 2, 3, 4, 5, 7, 8, 9, 10, 11];

    /// mapping(uint256 => TokenInfo) public tokenInfo;

    constructor(address _NEO) ERC721C("AIAlbumsMint", "AIA") {
        //give neo contract acces to transfer

        NEO = _NEO;
        drops[0].id = 0;
        drops[0].snapshot = 0;
        drops[0].ipfsHash = "";
        drops[0].ipfsPreview = "QmNssJaGjCGZANuE54CSkirRrSFf9FfGzGieWZUBWUMoPH";

        //loop through and create tokens but low gas
    }

    modifier adminAccess() {
        require(
            msg.sender == NEO ||
                msg.sender == The_Dude ||
                msg.sender == owner(),
            "Admin Access Required"
        );
        _;
    }

    modifier onlyValidAccess(
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _nonce,
        uint256 _drop,
        uint256 _index,
        address _signer
    ) {
        bytes32 hash = keccak256(
            abi.encodePacked(address(this), msg.sender, _nonce, _drop, _index)
        );
        address sender = ecrecover(
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            ),
            _v,
            _r,
            _s
        );
        require(sender == The_Dude, "Invalid access message.");
        nonces[msg.sender]++;
        _;
    }

    function addAttribute(AddAttribute memory _addAttribute)
        external
        adminAccess
    {
        attributes[_addAttribute.id]
            .info[_addAttribute.colorMapping.length]
            .svg = _addAttribute.svg;
        svgLayers[_addAttribute.id].attributes[
            attributes[_addAttribute.id].attributeCount
        ] = SVGAttributes(
            _addAttribute.colorMapping.length,
            _addAttribute.id,
            _addAttribute.colorMapping.length,
            _addAttribute.colorMapping
        );
        attributes[_addAttribute.id].attributeCount += 1;
    }

    function updateAttribute(
        uint32 id,
        uint32 layerId,
        string[] memory _svg
    ) public adminAccess {
        attributes[id].info[layerId].svg = _svg;
    }

    // function randomSpeciesColor(uint256 _seed)
    //     private
    //     view
    //     returns (bytes memory)
    // {
    //     return
    //         species.speciesColors[
    //             uint256(keccak256(abi.encodePacked(_seed, "speciesColor"))) %
    //                 speciesColorCount
    //         ];
    // }

    // function randomBackgroundType(uint256 _seed)
    //     private
    //     view
    //     returns (uint256)
    // {
    //     return _seed % bgTypeCount;
    // }

    // function generateSVG(uint32 id, uint256 _seed)
    //     internal
    //     view
    //     returns (bytes memory)
    // {
    //     uint256 svgNumber = _seed % svgList[id].count;

    //     uint256 varCount = svgLayers[id].attributes[svgNumber].varCount;
    //     uint32 oddFound = 0;
    //     uint256[] memory colorMapping = svgLayers[id]
    //         .attributes[svgNumber]
    //         .colorMapping;
    //     string[] memory _svg = svgList[id].layer[svgNumber].svg;

    //     //loop through string to create svg with required colors
    //     bytes memory svgBytes = abi.encodePacked(_svg[0]);

    //     bytes[] memory colorsArray = new bytes[](varCount);

    //     for (uint256 i = 1; i < _svg.length + varCount; i++) {
    //         //if odd then color is found
    //         if (i % 2 == 1) {
    //             colorsArray[oddFound] = colors[
    //                 svgLayers[id].attributes[svgNumber].colorId
    //             ].list[
    //                     uint256(keccak256(abi.encodePacked(i, _seed))) %
    //                         colors[id].count
    //                 ];
    //             svgBytes = abi.encodePacked(
    //                 svgBytes,
    //                 colorsArray[colorMapping[oddFound]]
    //             );
    //             oddFound++;
    //         } else {
    //             svgBytes = abi.encodePacked(svgBytes, _svg[i - oddFound]);
    //         }
    //     }
    //     if (id != 0) {
    //         svgBytes = abi.encodePacked(
    //             svg[0],
    //             svgList[id].layer[svgNumber].x,
    //             svg[1],
    //             svgList[id].layer[svgNumber].y,
    //             svg[2],
    //             svgBytes,
    //             svg[3]
    //         );
    //     }
    //     return svgBytes;
    // }

    // function generateHead(uint256 _seed) internal view returns (bytes memory) {
    //     return
    //         abi.encodePacked(
    //             headSvg[0],
    //             randomSpeciesColor(_seed),
    //             headSvg[1],
    //             randomEye(69),
    //             headSvg[1],
    //             bodySvg[0],
    //             randomSpeciesColor(_seed),
    //             bodySvg[1]
    //         );
    // }

    // function generateGradientBG(bool isSolid)
    //     internal
    //     view
    //     returns (bytes memory)
    // {
    //     //pick two random colors
    //     uint256 index1 = block.timestamp % gradientColorCount;
    //     uint256 index2 = (block.timestamp + 420) % gradientColorCount;

    //     if (isSolid) index2 = index1;

    //     if (index1 == index2 && !isSolid) {
    //         index2 = (index2 + 1) % gradientColorCount;
    //     }
    //     bytes memory c1 = backgrounds.gradientColors[index1];

    //     bytes memory c2 = backgrounds.gradientColors[index2];

    //     return
    //         abi.encodePacked(
    //             bgSvg[0],
    //             c1,
    //             bgSvg[1],
    //             c2,
    //             bgSvg[2],
    //             generateHead(block.timestamp),
    //             bgSvg[2]
    //         );
    // }

    function singatureClaimHash(
        uint256 _drop,
        uint256 _index,
        uint256 _nonce
    ) private view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(
                    address(this),
                    msg.sender,
                    _nonce,
                    _drop,
                    _index
                )
            );
    }

    function mintFamiliar(address _to) public {
        require(msg.sender == NEO, "Admin access only.");
        totalSupply++;
        //   require(!_exists(totalSupply), "ERC721: token already minted");
        //   ERC721C._balances[_to] += 1;
        //  _owners[totalSupply] = _to;
        _mint(_to, totalSupply);
    }

    // function mintTest(address _to, uint32 _amount) public {
    //     uint256 _amountToMint = _amount;
    //     while (_amountToMint > maxBatchSize) {
    //         _amountToMint -= maxBatchSize;
    //         _mintInternal(_to, maxBatchSize);
    //     }
    //     _mintInternal(_to, _amountToMint);
    // }

    //TODO: create metadata system
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!tokens[_tokenId].revealed) {
            return
                string(
                    abi.encodePacked(
                        "data:application/json;base64,",
                        Base64.encode(
                            abi.encodePacked(
                                '{"name":"Crypto-Mafia", "description":"An on-chain village or mafia member to join the game of crypto mafia.", "animation_url":"',
                                string(
                                    abi.encodePacked(
                                        baseURI,
                                        drops[0].ipfsPreview
                                    )
                                ),
                                '"}'
                            )
                        )
                    )
                );
        }

        // uint256 _seed = tokens[_tokenId].seed;

        // uint256 loopCount = tokens[_tokenId].layers.length;

        // //loop through count and generate svg
        // bytes memory _svg = abi.encodePacked(bgSvg[0], bgViewBox, bgSvg[1]);
        // for (uint256 i = 0; i < loopCount; i++) {
        //     uint32 layer = tokens[_tokenId].layers[i];
        //     _svg = abi.encodePacked(_svg, generateSVG(layer, _seed));
        // }

        // bytes memory _svg = abi.encodePacked(bgSvg[0], bgViewBox, bgSvg[1]);

        // uint32 layer = tokens[_tokenId].layers[0];

        bytes memory _attributes = abi.encodePacked(
            '"attributes":{"trait_type":"Mafia","value":"',
            tokens[_tokenId].isMafia ? "Yes" : "No",
            '"},'
        );

        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name":"Crypto-Mafia", "description":"An on-chain village or mafia member to join the game of crypto mafia.",',
                _attributes,
                '"image":"data:image/svg+xml;base64,',
                Base64.encode(""),
                '"}'
            )
        );
        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function safeTransferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override {
        require(NEO == msg.sender, "Familiar: Token is bound to NFT");

        _transfer(from_, to_, tokenId_);
    }

    function transferFrom(
        address from_,
        address to_,
        uint256 tokenId_
    ) public override {
        require(NEO == msg.sender, "Familiar: Token is bound to NFT");
        //make sure tokenId from other contract is owner of token this makes sure that only the owner can transfer
        //_transfer(from_, to_, tokenId_);
        _transfer(from_, to_, tokenId_);
    }

    // function _transfer(
    //     address from_,
    //     address to_,
    //     uint256 tokenId_
    // ) internal override {
    //     // cannot transfer to 0x0
    //     // require(to_ != address(0), "ERC721G: _transfer to 0x0");

    //     // delete any approvals
    //     //   delete getApproved[tokenId_];

    //     // set _tokenData to to_
    //     _tokenData[tokenId_].owner = to_;
    //     _tokenData[tokenId_].lastTransfer = _getBlockTimestampCompressed();

    //     // update the balance data
    //     unchecked {
    //         _balanceData[from_].balance--;
    //         _balanceData[to_].balance++;
    //     }

    //     // emit a standard Transfer
    //     emit Transfer(from_, to_, tokenId_);
    // }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        require(to != address(0), "ERC721: transfer to the zero address");

        // _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        //_approve(address(0), tokenId);

        ERC721C._balances[from] -= 1;
        ERC721C._balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        //  _afterTokenTransfer(from, to, tokenId);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721C.sol)
/**
 * This contract is a minimal, unimplemented fork of ERC721Enumerable.sol
 * for the purpose performing write optimizations on the ERC721Enumerable contract.
 */

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721C is Context, ERC165, IERC721 {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;

    // Mapping owner address to token count
    mapping(address => uint256) internal _balances;

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721: balance query for the zero address"
        );
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
        return owner;
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721C.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
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
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );

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
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
     * @dev Returns the raw owner for a given tokenId.
     */
    function _getOwner(uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721C.ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        address owner = ERC721C.ownerOf(tokenId);

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
        require(
            ERC721C.ownerOf(tokenId) == from,
            "ERC721: transfer from incorrect owner"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        //   _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        //     _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721C.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721: transfer to non ERC721Receiver implementer"
                    );
                } else {
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

    /** @dev requirement: You MUST implement your own tokenURI logic here
     *  recommended to use through an override function in your main contract.
     */
    function tokenURI(uint256 tokenId_)
        public
        view
        virtual
        returns (string memory)
    {}
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