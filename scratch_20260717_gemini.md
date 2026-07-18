Let's double-check the exact context strings from the `git status` terminal readouts you pasted earlier.

The values you are seeing in your bash prompts (`[uid1000]`, `[1001_ubu26]`, and `[id1003_...]`) are actually your local **Linux user IDs (UIDs)** or customized container hostname/prompt tags rather than the Windows host WSL internal subsystem registration UUIDs.

Here is the exact mapping extracted directly from your active session outputs:

### 1. The Dynamic Review Core (`uid1000`)

* **Prompt String:** `fekerr@LAPTOP-AJPE53SG:[uid1000]: ~/src/irislime`
* **Active User context:** This is your standard primary Linux user account (`uid=1000(fekerr)`) inside the **`ubu26_0715`** container workspace running the `agy-24-work` branch.

### 2. The Structural Preference Workspace (`1001_ubu26`)

* **Prompt String:** `fekerr@LAPTOP-AJPE53SG:[1001_ubu26]: ~/src/irislime`
* **Active User context:** This is your **`Ubuntu-26.04`** instance running the `20260713_irislime_user_preferences` branch. The prompt tag explicitly flags the environment as `1001_ubu26`.

### 3. The Heavy Analytics Engine (`1003`)

* **Prompt String:** `fekerr@LAPTOP-AJPE53SG:[id1003_...]: ~/src/irislime`
* **Active User context:** This is your **`Ubuntu-24.04`** telemetry environment running the `infra-telemetry-cleanup` branch. The user space is tagged as `id1003`.

---

### Adjusting the Chunker Directory Naming

Because these tags (`1000`, `1001`, `1003`) match how you dynamically identify these windows visually, they make the perfect naming convention for your cloud target subdirectories!

When you configure the PowerShell streaming execution block, it will look exactly like this to map your visual windows cleanly to your Google Drive remote targets:

```powershell
# 1. Target Directory: /irislime_reviews/20260717_719p/id1000/
wsl --export ubu26_0715 - | rclone rcat gdrive-chunked:id1000/ubu26_0715_review.tar --progress

# 2. Target Directory: /irislime_reviews/20260717_719p/id1001/
wsl --export Ubuntu-26.04 - | rclone rcat gdrive-chunked:id1001/ubuntu_2604_review.tar --progress

# 3. Target Directory: /irislime_reviews/20260717_719p/id1003/
wsl --export Ubuntu-24.04 - | rclone rcat gdrive-chunked:id1003/ubuntu_2404_review.tar --progress

```

This perfectly coordinates your terminal environments with the storage buckets. Let me know if you want to proceed with checking the code files inside `id1000` or kick off the stream!
