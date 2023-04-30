import {  expect } from "chai";
import {  ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("Test Gen0OnChainTokenURI", function () {
    let onChainTokenURI, kittyCoreTest;

    beforeEach(async function () {
        
        const KittyCoreTest = await ethers.getContractFactory("KittyCoreTest");
        kittyCoreTest = await KittyCoreTest.deploy();

        const Gen0OnChainTokenURI = await ethers.getContractFactory("Gen0OnChainTokenURI");       
        onChainTokenURI = await Gen0OnChainTokenURI.deploy(kittyCoreTest.address);               
    })

    describe("Gen0OnChainTokenURI ", function () {
        it("getKittyImage", async function () {
            const id1 =  3001;
            const id2 =  3002;
            await kittyCoreTest.mintGreaterThan3000(id1, 0);
            await kittyCoreTest.mintGreaterThan3000(id2, 0);
    

            expect(await onChainTokenURI.getKittyImage(id1)).equal("https://img.cryptokitties.co/0x06012c8cf97bead5deae237070f9587f8e7a266d/3001.png");
            expect(await onChainTokenURI.getKittyImage(id2)).equal("https://img.cryptokitties.co/0x06012c8cf97bead5deae237070f9587f8e7a266d/3002.png");

            let tokenURI1 = await onChainTokenURI.tokenURI(id1);
            let tokenURI2 = await onChainTokenURI.tokenURI(id2);

            await kittyCoreTest.mintTop100();
            await onChainTokenURI.tokenURI(1);

            await kittyCoreTest.mintTop3000();
            await onChainTokenURI.tokenURI(101);

        });
        
        it("getCooldownName", async function () {

            //  string[] private  _cooldownNames = ["Fast","Swift","Swift","Snappy","Snappy","Brisk","Brisk","Plodding","Plodding","Slow","Slow","Sluggish","Sluggish","Catatonic"];
            expect(await onChainTokenURI.getCooldownName(0)).equal("Fast");
            expect(await onChainTokenURI.getCooldownName(1)).equal("Swift");
            expect(await onChainTokenURI.getCooldownName(2)).equal("Swift");
            expect(await onChainTokenURI.getCooldownName(3)).equal("Snappy");
            expect(await onChainTokenURI.getCooldownName(4)).equal("Snappy");
            expect(await onChainTokenURI.getCooldownName(14)).equal("Unknown");
        });
    });

});

