export class UserKeys {

}

export default class UserKeysservice {

    constructor(private userUUID?: string) {

    }

    async findKey()  {

        if(this.userUUID){
            return prisma.users_keys.findFirst({
                select: {
                    key: true
                },
                where:{
                    uuid: this.userUUID
                }
            })
        }
    }
}