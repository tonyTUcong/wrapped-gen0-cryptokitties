import {  expect } from "chai";
import {  ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("Test 721WG0", function () {
    let owner, userA;
    let kittyCoreTest, wG0Test, wG0NFT,wVG0Test;

    beforeEach(async function () {
        [owner,userA] = await ethers.getSigners();
        const KittyCoreTest = await ethers.getContractFactory("KittyCoreTest");
        const WG0Test = await ethers.getContractFactory("WG0Test");
        const WVG0Test = await ethers.getContractFactory("WVG0Test");
        const WG0NFT = await ethers.getContractFactory("WrappedGen0CryptoKitties");

        kittyCoreTest = await KittyCoreTest.deploy();
        wG0Test = await WG0Test.deploy(kittyCoreTest.address);
        wVG0Test = await WVG0Test.deploy(kittyCoreTest.address);
        wG0NFT = await WG0NFT.deploy(kittyCoreTest.address, wG0Test.address, wVG0Test.address);
    })

    describe("wrap & unwrap ", function () {
        it("wrap &  unwrap", async function () {
            const id =  3001;
            const gen = 0;
            await kittyCoreTest.mintGreaterThan3000(id, gen,false);
            expect(await kittyCoreTest.ownerOf(id)).equal(owner.address);
    
            await kittyCoreTest.approve(wG0NFT.address, id);

            await wG0NFT.wrap(id);

            expect(await wG0NFT.ownerOf(id)).equal(owner.address);
            expect(await kittyCoreTest.ownerOf(id)).equal(wG0NFT.address);

            await wG0NFT.unwrap(id);
            expect(await kittyCoreTest.ownerOf(id)).equal(owner.address);

        });
        
        it("fail if the NFT is not Gen0", async function () {
            const id =  3002;
            const gen = 1;

            await kittyCoreTest.mintGreaterThan3000(id, gen,false);
            expect(await kittyCoreTest.ownerOf(id)).equal(owner.address);
    
            await kittyCoreTest.approve(wG0NFT.address, id);

            await expect(wG0NFT.wrap(id)).to.be.revertedWith("kitty must be Gen0");
        });
    });

    describe("swap between ERC-20(WG0, WVG0) and 721WG0", function () {

        it("swapFromWG0 & swapToWG0", async function () {
            const id1 = 3001;
            const id2 = 3002;
            const gen = 0;
            await kittyCoreTest.mintGreaterThan3000(id1, gen,false);
            await kittyCoreTest.approve(wG0Test.address, id1);

            await kittyCoreTest.mintGreaterThan3000(id2, gen,true);
            await kittyCoreTest.approve(wG0Test.address, id2);

            await wG0Test.depositKittiesAndMintTokens([id1, id2]);

            expect(await kittyCoreTest.ownerOf(id1)).equal(wG0Test.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(wG0Test.address);

            await wG0Test.approve(wG0NFT.address, ethers.utils.parseEther('2'));
            await wG0NFT.swapFromWG0([id1,id2], owner.address);
            expect(await wG0NFT.ownerOf(id1)).equal(owner.address);
            expect(await wG0NFT.ownerOf(id2)).equal(owner.address);
            expect(await kittyCoreTest.ownerOf(id1)).equal(wG0NFT.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(wG0NFT.address);

            await wG0NFT.swapToWG0([id1,id2], owner.address);
            expect(await kittyCoreTest.ownerOf(id1)).equal(wG0Test.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(wG0Test.address);

        });

        it("swapFromWVG0 & swapToWVG0", async function () {
            const id1 = 3001;
            const id2 = 3002;
            const gen = 0;
            await kittyCoreTest.mintGreaterThan3000(id1, gen,true);
            await kittyCoreTest.approve(wVG0Test.address, id1);

            await kittyCoreTest.mintGreaterThan3000(id2, gen,true);
            await kittyCoreTest.approve(wVG0Test.address, id2);

            await wVG0Test.depositKittiesAndMintTokens([id1, id2]);

            expect(await kittyCoreTest.ownerOf(id1)).equal(wVG0Test.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(wVG0Test.address);

            await wVG0Test.approve(wG0NFT.address, ethers.utils.parseEther('2'));
            await wG0NFT.swapFromWVG0([id1,id2], owner.address);
            expect(await wG0NFT.ownerOf(id1)).equal(owner.address);
            expect(await wG0NFT.ownerOf(id2)).equal(owner.address);
            expect(await kittyCoreTest.ownerOf(id1)).equal(wG0NFT.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(wG0NFT.address);

            await wG0NFT.swapToWVG0([id1,id2], owner.address);
            expect(await kittyCoreTest.ownerOf(id1)).equal(wVG0Test.address);
            expect(await kittyCoreTest.ownerOf(id2)).equal(wVG0Test.address);

        });

        it("invalid count", async function () {
            await expect(wG0NFT.swapFromWG0([],owner.address)).to.be.revertedWith("invalid count");
            await expect(wG0NFT.swapToWG0([],owner.address)).to.be.revertedWith("invalid count");
        });

        it("not owner", async function () {

            const id =  3001;
            const gen = 0;
            await kittyCoreTest.mintGreaterThan3000(id, gen,true);
            expect(await kittyCoreTest.ownerOf(id)).equal(owner.address);
    
            await kittyCoreTest.approve(wG0NFT.address, id);

            await wG0NFT.wrap(id);

            await expect(wG0NFT.connect(userA).swapToWG0([id],owner.address)).to.be.revertedWith("not owner");
        });
        
    });
});

