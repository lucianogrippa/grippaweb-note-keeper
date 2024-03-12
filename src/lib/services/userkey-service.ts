export class UserKeys {

}

export default class UserKeysservice {


    constructor(private userUUID?: string) {

    }

    async findKey() {

        if (this.userUUID) {
            return prisma.users_keys.findFirst({
                select: {
                    key: true
                },
                where: {
                    uuid: this.userUUID
                }
            })
        }
    }

    async save(saltedPassword: string): Promise<{
        id: number,
        key: string,
        uuid: string
    } | null> {

        try {

            const savedKey = await prisma.users_keys.create({
                include: {
                    categories: false,
                    fields: false,
                    secreats: false
                },
                data: {
                    key: saltedPassword,
                    uuid: this.userUUID
                }
            });

            if(!!savedKey){
                return {
                    id: savedKey.id,
                    key: savedKey.key,
                    uuid: savedKey.uuid
                }
            }
        } catch (error) {
            console.error(error);
        }
        return null;
    }
}