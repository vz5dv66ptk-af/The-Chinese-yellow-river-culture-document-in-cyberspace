
import { http } from '@kit.NetworkKit';
import { QingLuanVoice } from './voice';
import promptAction from '@ohos.promptAction';
import router from '@ohos.router';
import { KbEntry, KB } from './introduce';
import { EntryItem, ENTRIES } from '../models/data';
import { ALIAS_KEYS, ALIAS_TITLES } from '../models/alias';

PersistentStorage.PersistProp('llmBase', 'http://127.0.0.1:8788/v1');
PersistentStorage.PersistProp('llmModel', 'deepseek-flash');
PersistentStorage.PersistProp('qlToken', '');
PersistentStorage.PersistProp('qlUser', '');
PersistentStorage.PersistProp('llmKey', '');

interface AuthResp {
  token: string;
  user: string;
  limit: number;
  model: string;
}

interface AuthErrInner {
  message: string;
}

interface AuthErr {
  error: AuthErrInner;
}

interface ChatMsg {
  id: number;
  role: string;
  text: string;
  entry?: string;
  src?: string;
}

interface ApiMessage {
  role: string;
  content: string;
}

interface ApiChoice {
  message: ApiMessage;
}

interface ApiResp {
  choices: ApiChoice[];
}

const PUNCT = /[\s，。、？！：；「」『』（）()《》〈〉,.!?:\-—~·]+/g;
const S_PLACE: string[] = ['在哪', '哪里', '哪个市', '哪个省', '什么地方', '位置', '地址', '属于'];
const S_PERIOD: string[] = ['哪年', '什么时候', '年代', '时期', '哪个朝代', '多少年', '距今', '几年'];
const S_SIZE: string[] = ['多重', '多大', '多高', '多长', '多宽', '尺寸', '重量', '几米', '几公斤',
  '多少米', '多少公斤', '多大面积', '多深', '多少件', '几件', '多少座', '多少尊', '多少片', '多少层'];
const S_FINDS: string[] = ['出土', '发现', '挖出', '里面有什么', '有什么东西'];

const POSE_CALM: number = 1;
const POSE_BLINK: number = 2;
const POSE_THINK: number = 34;
const POSE_HAPPY: number = 29;
const POSE_SHY: number = 31;
const POSE_SAD: number = 30;
const POSE_SURPRISE: number = 25;
const IDLE_CYCLE: number[] = [9, 11, 13, 14, 8, 17, 21, 24, 28, 33, 35, 40];
const BLINK_HOLD_MS: number = 1000;
const BLINK_GAP_MIN_MS: number = 4200;
const BLINK_GAP_RANGE_MS: number = 4800;

const POSE_RES: Resource[] = [
  $r('app.media.qingluan_p1'), $r('app.media.qingluan_p2'), $r('app.media.qingluan_p3'),
  $r('app.media.qingluan_p4'), $r('app.media.qingluan_p5'), $r('app.media.qingluan_p6'),
  $r('app.media.qingluan_p7'), $r('app.media.qingluan_p8'), $r('app.media.qingluan_p9'),
  $r('app.media.qingluan_p10'), $r('app.media.qingluan_p11'), $r('app.media.qingluan_p12'),
  $r('app.media.qingluan_p13'), $r('app.media.qingluan_p14'), $r('app.media.qingluan_p15'),
  $r('app.media.qingluan_p16'), $r('app.media.qingluan_p17'), $r('app.media.qingluan_p18'),
  $r('app.media.qingluan_p19'), $r('app.media.qingluan_p20'), $r('app.media.qingluan_p21'),
  $r('app.media.qingluan_p22'), $r('app.media.qingluan_p23'), $r('app.media.qingluan_p24'),
  $r('app.media.qingluan_p25'), $r('app.media.qingluan_p26'), $r('app.media.qingluan_p27'),
  $r('app.media.qingluan_p28'), $r('app.media.qingluan_p29'), $r('app.media.qingluan_p30'),
  $r('app.media.qingluan_p31'), $r('app.media.qingluan_p32'), $r('app.media.qingluan_p33'),
  $r('app.media.qingluan_p34'), $r('app.media.qingluan_p35'), $r('app.media.qingluan_p36'),
  $r('app.media.qingluan_p37'), $r('app.media.qingluan_p38'), $r('app.media.qingluan_p39'),
  $r('app.media.qingluan_p40'),
];

function poseResById(n: number): Resource {
  if (n >= 1 && n <= 40) {
    return POSE_RES[n - 1];
  }
  return $r('app.media.qingluan_p1');
}

const S_WHO: string[] = ['谁', '哪位', '哪个王'];

@Entry
@Component
export struct assistant {
  @StorageLink('llmBase') llmBase: string = 'http://127.0.0.1:8788/v1';
  @StorageLink('llmModel') llmModel: string = 'deepseek-flash';
  @StorageLink('llmKey') llmKey: string = '';
  @StorageLink('qlToken') qlToken: string = '';
  @StorageLink('qlUser') qlUser: string = '';
  @State authUser: string = '';
  @State authPass: string = '';
  @State authMsg: string = '';

  @State msgs: ChatMsg[] = [];
  @State draft: string = '';
  @State busy: boolean = false;
  @State showSet: boolean = false;
  @State formBase: string = '';
  @State formModel: string = '';
  @State formKey: string = '';
  @State testResult: string = '';
  @State pose: number = POSE_CALM;
  @State blinking: boolean = false;

  private seq: number = 0;
  private poseTimer: number = -1;
  private blinkTimer: number = -1;
  private idleTimer: number = -1;
  private basePose: number = POSE_CALM;
  private idleIndex: number = 0;
  private idleClock: number = 0;
  private idleOn: boolean = false;
  private lastActive: number = Date.now();
  private lastArtTitle: string = '';
  private modelDown: boolean = false;
  private lastErr: string = '';
  private scroller: Scroller = new Scroller();
  private voice: QingLuanVoice = new QingLuanVoice();
  @State ttsOn: boolean = true;

  aboutToAppear(): void {
    this.voice.init();
    this.bot('我是青鸾，黄河记忆的文化向导。想听哪一段——河道、遗址，还是某件器物？', 'bot');
    this.loopBlink();
    this.idleTimer = setInterval(() => {
      this.tickIdle();
    }, 1000);
  }

  aboutToDisappear(): void {
    this.voice.release();
    if (this.poseTimer !== -1) {
      clearTimeout(this.poseTimer);
      this.poseTimer = -1;
    }
    if (this.blinkTimer !== -1) {
      clearTimeout(this.blinkTimer);
      this.blinkTimer = -1;
    }
    if (this.idleTimer !== -1) {
      clearInterval(this.idleTimer);
      this.idleTimer = -1;
    }
  }

  private apiRoot(): string {
    let b: string = this.llmBase.trim();
    if (b.endsWith('/v1')) {
      b = b.substring(0, b.length - 3);
    }
    if (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    return b;
  }

  private async doAuth(path: string): Promise<void> {
    const u: string = this.authUser.trim();
    const p: string = this.authPass;
    if (u.length < 2 || p.length < 6) {
      this.authMsg = '用户名至少 2 位，密码至少 6 位';
      return;
    }
    this.authMsg = '处理中…';
    const req = http.createHttp();
    try {
      const res = await req.request(this.apiRoot() + path, {
        method: http.RequestMethod.POST,
        header: { 'Content-Type': 'application/json' },
        extraData: JSON.stringify({ username: u, password: p }),
        connectTimeout: 10000,
        readTimeout: 20000
      });
      const text: string = res.result as string;
      if (res.responseCode === 200 || res.responseCode === 201) {
        const data: AuthResp = JSON.parse(text) as AuthResp;
        this.qlToken = data.token;
        this.qlUser = data.user.length > 0 ? data.user : u;
        this.authMsg = '';
        this.authPass = '';
        this.bot('你好，' + this.qlUser + '。我是青鸾，黄河记忆的文化向导。想听哪一段？', 'bot');
      } else {
        let msg: string = '失败（HTTP ' + res.responseCode + '）';
        try {
          const err = JSON.parse(text) as AuthErr;
          if (err.error !== undefined && err.error.message.length > 0) {
            msg = err.error.message;
          }
        } catch (e) {}
        this.authMsg = msg;
      }
    } catch (err) {
      this.authMsg = '连不上服务器：' + this.apiRoot();
    } finally {
      req.destroy();
    }
  }

  private poseRes(n: number): Resource {
    return poseResById(n);
  }

  private moodPose(mood: string): number {
    if (mood === 'think') {
      return POSE_THINK;
    } else if (mood === 'happy') {
      return POSE_HAPPY;
    } else if (mood === 'shy') {
      return POSE_SHY;
    } else if (mood === 'sad') {
      return POSE_SAD;
    } else if (mood === 'surprise') {
      return POSE_SURPRISE;
    }
    return this.basePose;
  }

  private showPose(n: number, holdMs: number): void {
    this.pose = n;
    if (this.poseTimer !== -1) {
      clearTimeout(this.poseTimer);
      this.poseTimer = -1;
    }
    if (holdMs > 0 && n !== this.basePose) {
      this.poseTimer = setTimeout(() => {
        this.pose = this.basePose;
        this.poseTimer = -1;
      }, holdMs);
    }
  }

  private loopBlink(): void {
    this.blinkTimer = setTimeout(() => {
      if (!this.busy && this.pose === POSE_CALM) {
        this.blinking = true;
        setTimeout(() => {
          this.blinking = false;
        }, BLINK_HOLD_MS);
      }
      this.loopBlink();
    }, BLINK_GAP_MIN_MS + Math.random() * BLINK_GAP_RANGE_MS);
  }

  private tickIdle(): void {
    const quiet: number = Date.now() - this.lastActive;
    const canIdle: boolean = !this.busy && quiet >= 10000;
    if (!canIdle) {
      if (this.idleOn) {
        this.idleOn = false;
        this.pose = this.basePose;
      }
      this.idleClock = 0;
      return;
    }
    if (!this.idleOn) {
      this.idleOn = true;
      this.idleIndex = 0;
      this.idleClock = 0;
      this.basePose = IDLE_CYCLE[0];
      this.pose = this.basePose;
      return;
    }
    this.idleClock = this.idleClock + 1;
    if (this.idleClock >= 10) {
      this.idleClock = 0;
      this.idleIndex = (this.idleIndex + 1) % IDLE_CYCLE.length;
      this.pose = IDLE_CYCLE[this.idleIndex];
    }
  }

  @Builder
  stage() {
    Stack({ alignContent: Alignment.Bottom }) {
      Image(this.blinking ? this.poseRes(POSE_BLINK) : this.poseRes(this.pose))
        .width('100%')
        .height(200)
        .objectFit(ImageFit.Contain)
        .onClick(() => {
          this.lastActive = Date.now();
          this.showPose(
            [10, 23, 26, 33, 39][Math.floor(Math.random() * 5)],
            2200
          );
        })
      Text('青鸾 · 黄河记忆文化向导')
        .fontSize(9)
        .fontColor('#8C8474')
        .padding({ left: 8, right: 8, top: 2, bottom: 2 })
        .backgroundColor('#FFFDF8CC')
        .borderRadius(999)
        .margin({ bottom: 4 })
    }
    .width('100%')
    .height(210)
    .linearGradient({ angle: 180, colors: [['#EBD5AE', 0], ['#D3B385', 1]] })
    .border({ width: { bottom: 1 }, color: '#D6BC90' })
  }

  private bot(text: string, role: string, entry?: string, src?: string): void {
    this.seq = this.seq + 1;
    const m: ChatMsg = { id: this.seq, role: role, text: text };
    if (entry !== undefined && entry.length > 0) {
      m.entry = entry;
    }
    if (src !== undefined && src.length > 0) {
      m.src = src;
    }
    this.msgs.push(m);
    this.msgs = this.msgs.slice();
    this.scrollBottom();
    if (role !== 'user' && role !== 'sys') {
      try {
        this.voice.setEnabled(this.ttsOn);
        this.voice.say(text);
      } catch (e) {
      }
    }
  }

  private smallTalk(t: string): string {
    const q: string = t.replace(/\s/g, '');
    if (/^(你好|您好|hi|hello|嗨)/i.test(q)) {
      return '你好。我是青鸾，守着这条河的档案。想看哪一件？';
    }
    if (/^(谢谢|多谢|感谢)/.test(q)) {
      return '不客气。河很长，慢慢看。';
    }
    if (/(你是谁|你叫什么|自我介绍)/.test(q)) {
      return '我叫青鸾，黄河记忆里的向导。121 件文物、遗址与器物，大致都记得。';
    }
    if (/(你能做什么|会什么|怎么用|能帮我什么)/.test(q)) {
      return '三件事：讲一件文物的形制与来历；按年代、类型、省份帮你挑；也能陪你聊两句。';
    }
    if (/^(再见|拜拜|bye)/i.test(q)) {
      return '慢走。下次来，我给你讲别的。';
    }
    return '';
  }

  private aggregate(t: string): string {
    const q: string = t.replace(/\s/g, '');
    const wantCount: boolean = /(几件|多少件|有几|共多少|多少种|统计|一共)/.test(q);
    const wantList: boolean = /(哪些|分别|列举|都有什么|看看|有什么)/.test(q);
    if (!wantCount && !wantList) {
      return '';
    }
    const types: string[] = ['青铜器', '陶器', '瓷器', '玉器', '金银器', '石刻造像',
      '书画', '简牍典籍', '乐器', '遗址建筑', '其他'];
    let type: string = '';
    for (let i = 0; i < types.length; i++) {
      if (q.indexOf(types[i]) >= 0) {
        type = types[i];
        break;
      }
    }

    const qq: string = type.length > 0 ? q.split(type).join('') : q;
    let era: string = '';
    if (/金代|金朝|辽金/.test(qq)) {
      era = '金';
    } else if (/汉代|西汉|东汉|汉墓/.test(qq)) {
      era = '汉';
    } else {
      const eras: string[] = ['新石器', '仰韶', '龙山', '二里头', '夏', '商', '周', '秦',
        '魏晋', '北齐', '隋', '唐', '宋', '元', '明', '清'];
      for (let j = 0; j < eras.length; j++) {
        if (qq.indexOf(eras[j]) >= 0) {
          era = eras[j];
          break;
        }
      }
    }
    if (type.length === 0 && era.length === 0) {
      return '';
    }

    const hits: EntryItem[] = [];
    for (let k = 0; k < ENTRIES.length; k++) {
      const e: EntryItem = ENTRIES[k];
      const okT: boolean = type.length === 0 || e.type === type;
      const okE: boolean = era.length === 0 || e.eraFull.indexOf(era) >= 0 || e.era.indexOf(era) >= 0;
      if (okT && okE) {
        hits.push(e);
      }
    }
    const label: string = era + type;
    if (hits.length === 0) {
      return '「' + label + '」这一类档案里没有收录。换个年代或类型试试。';
    }
    if (wantCount && !wantList) {
      const names: string[] = [];
      for (let m = 0; m < hits.length && m < 5; m++) {
        names.push(hits[m].title);
      }
      const tail: string = hits.length > 5 ? ('比如 ' + names.join('、') + ' 等。') : (names.join('、') + '。');
      return '「' + label + '」共 ' + hits.length + ' 件。' + tail;
    }
    const lines: string[] = [];
    for (let n = 0; n < hits.length && n < 10; n++) {
      lines.push('· ' + hits[n].title + '（' + (hits[n].eraFull.length > 0 ? hits[n].eraFull : '年代待考') + '）');
    }
    const more: string = hits.length > 10 ? ('\n…还有 ' + (hits.length - 10) + ' 件') : '';
    return '「' + label + '」' + hits.length + ' 件：\n' + lines.join('\n') + more;
  }

  private resolvePronoun(t: string): EntryItem | null {
    if (this.lastArtTitle.length === 0) {
      return null;
    }
    const q: string = t.replace(/\s/g, '');
    const hit: boolean = /^(它|他|她|这个|这件|那件|这东西|还有呢|然后呢|接着说|继续)/.test(q)
      || (/(它|这件|这个)/.test(q) && q.length <= 12);
    if (!hit) {
      return null;
    }
    for (let i = 0; i < ENTRIES.length; i++) {
      if (ENTRIES[i].title === this.lastArtTitle) {
        return ENTRIES[i];
      }
    }
    return null;
  }

  private moreOf(e: EntryItem): string {
    let out: string = '《' + e.title + '》\n';
    if (e.story.length > 0) {
      out += '背景：' + e.story + '\n';
    }
    if (e.related.length > 0) {
      out += '相关：' + e.related;
    }
    if (out.indexOf('背景') < 0 && out.indexOf('相关') < 0) {
      out += e.detail.length > 0 ? e.detail : (e.summary.length > 0 ? e.summary : '（这一条还没有更多内容）');
    }
    return out.trim();
  }

  private qlNorm(t: string): string {
    const map: string[] = ['後后', '國国', '壺壶', '銅铜', '馬马', '鏡镜', '劍剑', '簡简',
      '齊齐', '龍龙', '飛飞', '車车', '書书', '畫画', '漢汉', '晉晋', '趙赵', '鳳凤',
      '雲云', '紋纹', '鐵铁', '銀银', '窯窑', '磚砖', '獸兽', '鳥鸟', '魚鱼', '龜龟',
      '鶴鹤', '戰战', '軍军', '髮发', '飾饰', '絲丝', '繡绣', '錦锦', '雞鸡', '萬万',
      '兩两', '個个', '時时', '東东', '長长', '門门', '開开', '關关', '陽阳', '縣县'];
            let q: string = t.replace(/[\s，。、？！：；「」『』（）()《》〈〉,.!?:;\-—~·]/g, '');
    for (let i = 0; i < map.length; i++) {
      q = q.split(map[i].substring(0, 1)).join(map[i].substring(1, 2));
    }
    return q.toLowerCase();
  }

  private byTitle(title: string): EntryItem | null {
    return ENTRIES.find((e: EntryItem) => e.title === title) ?? null;
  }

  private suggestArt(q: string, n: number): string[] {
    const t: string = this.qlNorm(q);
    const out: string[] = [];
    if (t.length === 0) {
      return out;
    }
    const names: string[] = [];
    const scores: number[] = [];
    for (let i = 0; i < ENTRIES.length; i++) {
      const e: EntryItem = ENTRIES[i];
      const tt: string = this.qlNorm(e.title);
      let hit: number = 0;
      for (let k = 0; k < t.length; k++) {
        if (tt.indexOf(t.charAt(k)) >= 0) {
          hit += 1;
        }
      }
      let runs: number = 0;
      for (let k2 = 0; k2 + 2 <= t.length; k2++) {
        if (tt.indexOf(t.substring(k2, k2 + 2)) >= 0) {
          runs += 1;
        }
      }
      const sc: number = hit / Math.max(t.length, 1) + runs * 0.15;
      if (sc >= 0.25) {
        names.push(e.title);
        scores.push(sc);
      }
    }
    let indices: number[] = [];
    for (let i = 0; i < names.length; i++) { indices.push(i); }
    indices.sort((a: number, b: number) => scores[b] - scores[a]);
    for (let m = 0; m < indices.length && m < n; m++) {
      out.push(names[indices[m]]);
    }
    return out;
  }

  private srcLine(kind: string, art: EntryItem | null): string {

    return '';
  }

  private findArt(text: string): EntryItem | null {
    const q: string = this.qlNorm(text);
    if (q.length === 0) {
      return null;
    }
    // 1) 全名
    let best: EntryItem | null = null;
    let bestLen: number = 0;
    for (let i = 0; i < ENTRIES.length; i++) {
      const e: EntryItem = ENTRIES[i];
      const t: string = this.qlNorm(e.title);
      if (t.length >= 2 && q.indexOf(t) >= 0 && t.length > bestLen) {
        best = e;
        bestLen = t.length;
      }
    }
    if (best !== null) {
      return best;
    }
    for (let k = 0; k < ENTRIES.length; k++) {
      const e: EntryItem = ENTRIES[k];
      const t2: string = this.qlNorm(e.title);
      if (t2.length < 3) {
        continue;
      }
      if (q.indexOf(t2.substring(0, 3)) >= 0 && t2.length > bestLen) {
        best = e;
        bestLen = t2.length;
      }
    }
    if (best !== null) {
      return best;
    }

    let aliasTitle: string = '';
    let aliasLen: number = 0;
    for (let a = 0; a < ALIAS_KEYS.length; a++) {
      const key: string = this.qlNorm(ALIAS_KEYS[a]);
      if (key.length >= 2 && q.indexOf(key) >= 0 && key.length > aliasLen) {
        aliasTitle = ALIAS_TITLES[a];
        aliasLen = key.length;
      }
    }
    if (aliasTitle.length > 0) {
      const hit: EntryItem | null = this.byTitle(aliasTitle);
      if (hit !== null) {
        return hit;
      }
    }
    for (let m = 0; m < ENTRIES.length; m++) {
      const e: EntryItem = ENTRIES[m];
      const t3: string = this.qlNorm(e.title);
      if (t3.length < 3) {
        continue;
      }
      let run: number = 0;
      for (let s = 0; s + 2 <= t3.length; s++) {
        if (q.indexOf(t3.substring(s, s + 2)) >= 0) {
          run += 1;
        }
      }
      if (run >= 2 && t3.length > bestLen) {
        best = e;
        bestLen = t3.length;
      }
    }
    return best;
  }

  private clipText(t: string, n: number): string {
    const v: string = t.trim();
    return v.length > n ? (v.substring(0, n) + '…') : v;
  }

  private artAnswer(e: EntryItem): string {
    let out: string = '《' + e.title + '》\n';
    const meta: string[] = [];
    if (e.eraFull.length > 0) {
      meta.push(e.eraFull);
    }
    if (e.loc.length > 0) {
      meta.push(e.loc);
    }
    if (e.type.length > 0) {
      meta.push(e.type);
    }
    if (meta.length > 0) {
      out += meta.join(' · ') + '\n';
    }
    if (e.summary.length > 0) {
      out += e.summary + '\n';
    }
    const facts: string[] = [];
    if (e.spec.length > 0 && e.spec !== '待核') {
      facts.push('规格：' + e.spec);
    }
    if (e.material.length > 0 && e.material !== '—') {
      facts.push('材质：' + e.material);
    }
    if (e.museum.length > 0) {
      facts.push('馆藏：' + e.museum);
    }
    if (facts.length > 0) {
      out += '· ' + facts.join('\n· ') + '\n';
    }

    if (e.form.length > 0) {
      out += '形制：' + this.clipText(e.form, 72) + '\n';
    }
    if (e.meaning.length > 0) {
      out += '意义：' + this.clipText(e.meaning, 72) + '\n';
    }

    const plain: boolean = e.form.length === 0 && e.story.length === 0 && e.meaning.length === 0;
    if (!plain && e.detail.length > 0) {
      out += e.detail.length > 90 ? (e.detail.substring(0, 90) + '…') : e.detail;
    }
    return out.trim();
  }

  private scrollBottom(): void {
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 60);
  }

  private history(): ApiMessage[] {
    const out: ApiMessage[] = [];
    const start: number = Math.max(0, this.msgs.length - 8);
    for (let i = start; i < this.msgs.length; i++) {
      const m: ChatMsg = this.msgs[i];
      if (m.role === 'user' || m.role === 'bot') {
        out.push({ role: m.role === 'user' ? 'user' : 'assistant', content: m.text });
      }
    }
    return out;
  }

  private norm(t: string): string {
    return t.replace(PUNCT, '').toLowerCase();
  }

  private hasAny(list: string[], s: string): boolean {
    return list.some((item: string) => s.indexOf(item) >= 0);
  }
  private pickEntry(text: string): KbEntry | null {
    const s: string = this.norm(text);
    let best: KbEntry | null = null;
    let bestLen: number = 0;
    for (let i = 0; i < KB.length; i++) {
      const e: KbEntry = KB[i];
      const names: string[] = [e.name];
      for (let k = 0; k < e.alias.length; k++) {
        names.push(e.alias[k]);
      }
      for (let n = 0; n < names.length; n++) {
        const nn: string = this.norm(names[n]);
        if (nn.length >= 2 && s.indexOf(nn) >= 0 && nn.length > bestLen) {
          best = e;
          bestLen = nn.length;
        }
      }
    }
    return best;
  }

  private hasNumber(t: string): boolean {
    for (let i = 0; i < 10; i++) {
      if (t.indexOf(i.toString()) >= 0) {
        return true;
      }
    }
    return false;
  }

  private kbAnswer(text: string): string {
    const e: KbEntry | null = this.pickEntry(text);
    if (e === null) {
      return '';
    }
    const s: string = this.norm(text);
    const facts: string[] = e.facts;

    if (this.hasAny(S_SIZE, s)) {
      const sized: string[] = [];
      for (let i = 0; i < facts.length && sized.length < 3; i++) {
        if (this.hasNumber(facts[i])) {
          sized.push(facts[i]);
        }
      }
      if (sized.length > 0) {
        return e.name + '的关键数据：\n· ' + sized.join('\n· ');
      }
    }
    if (this.hasAny(S_FINDS, s)) {
      const got: string[] = [];
      for (let i = 0; i < facts.length && got.length < 4; i++) {
        if (facts[i].indexOf('出土') >= 0 || facts[i].indexOf('发现') >= 0) {
          got.push(facts[i]);
        }
      }
      if (got.length > 0) {
        return e.name + '出土/发现了这些：\n· ' + got.join('\n· ');
      }
    }
    if (this.hasAny(S_PLACE, s) && e.place.length > 0) {
      return e.name + '在' + e.place + '。' + (e.period.length > 0 ? '（' + e.period + '）' : '');
    }
    if (this.hasAny(S_PERIOD, s) && e.period.length > 0) {
      return e.name + '的年代：' + e.period + '。';
    }
    let body: string = e.summary;
    if (facts.length > 0) {
      body += '\n· ' + facts.slice(0, 2).join('\n· ');
    }
    return body;
  }

  private kbContext(text: string): string {
    const e: KbEntry | null = this.pickEntry(text);
    if (e === null) {
      return '';
    }
    return '《' + e.name + '》\n年代：' + (e.period.length > 0 ? e.period : '未知') +
      '　地点：' + (e.place.length > 0 ? e.place : '未知') +
      '\n概述：' + e.summary + '\n要点：' + e.facts.join('；') + '\n出处：' + e.source;
  }

  private async callLLM(text: string): Promise<string> {
    const ctx: string = this.kbContext(text);
    const sys: string = '你是「青鸾」，黄河记忆 App 的文化向导：年轻、有见识、说话克制而亲近，' +
      '像一位懂行的朋友，不是查询接口。\n' +
      '【怎么答】\n' +
      '1. 问到档案里的文物/遗址时，优先用【参考资料】，答得具体、有细节。\n' +
      '2. 资料为空或不够时，用你自己的知识正常回答——可以聊天、可以解释、可以追问；' +
      '但涉及具体年代、尺寸、重量、人名时，没把握就说明「这点我不确定」，不要编造。\n' +
      '3. 顺着上下文接话：用户说「它」「这个」「还有呢」，要明白指上一件文物。\n' +
      '4. 口语化、简洁，一般 2-4 句，用户要展开时再展开。\n\n【参考资料】\n' +
      (ctx.length > 0 ? ctx : '（本次没有检索到对应条目）');

    const msgs: ApiMessage[] = [{ role: 'system', content: sys }];
    const hist: ApiMessage[] = this.history();
    for (let i = 0; i < hist.length; i++) {
      msgs.push(hist[i]);
    }
    const last: ApiMessage = msgs[msgs.length - 1];
    if (last.role !== 'user' || last.content !== text) {
      msgs.push({ role: 'user', content: text });
    }

    const req = http.createHttp();
    try {
      let base: string = this.llmBase.trim();
      while (base.length > 0 && base.charAt(base.length - 1) === '/') {
        base = base.substring(0, base.length - 1);
      }
      const res = await req.request(base + '/chat/completions', {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + (this.qlToken.length > 0 ? this.qlToken : this.llmKey.trim())
        },
        extraData: JSON.stringify({
          model: this.llmModel.trim().length > 0 ? this.llmModel.trim() : 'deepseek-flash',
          messages: msgs,
          temperature: 0.3,
          stream: false,
          max_tokens: 600
        }),
        connectTimeout: 4000,
        readTimeout: 40000
      });
      if (res.responseCode === 200 && typeof res.result === 'string') {
        const data: ApiResp = JSON.parse(res.result as string) as ApiResp;
        if (data.choices && data.choices.length > 0) {
          const content: string = data.choices[0].message.content;
          if (content !== undefined && content.length > 0) {
            return content.trim();
          }
        }
        this.lastErr = '返回为空';
        return '';
      }
      this.lastErr = 'HTTP ' + res.responseCode;
      return '';
    } catch (err) {
      this.lastErr = '请求失败（网络或地址不对）';
      return '';
    } finally {
      req.destroy();
    }
  }

  private async send(text?: string): Promise<void> {
    const t: string = (text === undefined ? this.draft : text).trim();
    if (t.length === 0 || this.busy) {
      return;
    }
    if (text === undefined) {
      this.draft = '';
    }
    this.bot(t, 'user');
    this.busy = true;
    this.lastActive = Date.now();
    this.showPose(POSE_THINK, 0);

    // 0) 闲聊（没配模型时也要像在说话）
    if (this.llmBase.trim().length === 0) {
      const st: string = this.smallTalk(t);
      if (st.length > 0) {
        this.bot(st, 'local');
        this.showPose(1, 2800);
        return;
      }
    }

    const agg: string = this.aggregate(t);
    if (agg.length > 0) {
      this.bot(agg, 'local', '', this.srcLine('stat', null));
      this.showPose(1, 2800);
      return;
    }

    let art: EntryItem | null = this.findArt(t);

    if (art === null) {
      const prev: EntryItem | null = this.resolvePronoun(t);
      if (prev !== null) {
        if (/还有呢|然后呢|接着说|继续/.test(t)) {
          this.bot(this.moreOf(prev), 'bot', prev.title, this.srcLine('art', prev));
          this.showPose(1, 2800);
          return;
        }
        art = prev;
      }
    }
    if (art !== null) {
      this.lastArtTitle = art.title;
    }

    if (!this.modelDown && this.llmBase.trim().length > 0) {
      const reply: string = await this.callLLM(t);
      this.busy = false;
      if (reply.length > 0) {
        this.bot(reply, 'bot', art === null ? '' : art.title, this.srcLine('model', art));
        this.showPose(1, 2800);
        return;
      }
      this.modelDown = true;
      this.bot('接口没通：' + this.lastErr + '（已改用本地资料回答）', 'sys');
    } else {
      this.busy = false;
    }

    if (art !== null) {
      this.bot(this.artAnswer(art), 'bot', art.title, this.srcLine('art', art));
      this.showPose(1, 2800);
      return;
    }

    const local: string = this.kbAnswer(t);
    if (local.length > 0) {
      this.bot(local, 'bot', '', this.srcLine('kb', null));
      this.showPose(1, 2800);
      return;
    }
    const near: string[] = this.suggestArt(t, 3);
    let msg: string = '档案里没有「' + t.substring(0, 12) + '」这一条。\n当前收录 '
      + ENTRIES.length + ' 件，年代与类型都能查。';
    if (near.length > 0) {
      msg += '\n你要找的可能是：';
      for (let i = 0; i < near.length; i++) {
        msg += '\n· ' + near[i];
      }
    } else {
      msg += '\n可以试试「唐代有哪些青铜器」这样的问法。';
    }
    this.bot(msg, 'bot');
    this.showPose(1, 2800);
  }

  @Builder
  authView() {
    Column() {
      Text('登录后即可对话')
        .fontSize(18).fontWeight(FontWeight.Bold).fontColor('#2B241A').fontFamily('serif')
      Text('注册一个账号（不需要邮箱），每天有免费对话次数')
        .fontSize(11).fontColor('#8C8474').margin({ top: 6, bottom: 18 })
      TextInput({ text: this.authUser, placeholder: '用户名（2-20 位）' })
        .fontSize(13).height(44).backgroundColor('#F7F1E3').borderRadius(11).margin({ bottom: 9 })
        .onChange((v: string) => { this.authUser = v; })
      TextInput({ text: this.authPass, placeholder: '密码（至少 6 位）' })
        .type(InputType.Password)
        .fontSize(13).height(44).backgroundColor('#F7F1E3').borderRadius(11).margin({ bottom: 9 })
        .onChange((v: string) => { this.authPass = v; })
      Row() {
        Button('登录')
          .fontSize(14).height(44).layoutWeight(1).borderRadius(11)
          .backgroundColor('#B8863B').fontColor(Color.White)
          .onClick(() => { this.doAuth('/api/login'); })
        Button('注册')
          .fontSize(14).height(44).layoutWeight(1).borderRadius(11).margin({ left: 9 })
          .backgroundColor('#F3E9D2').fontColor('#2B241A')
          .onClick(() => { this.doAuth('/api/register'); })
      }
      .width('100%')
      if (this.authMsg.length > 0) {
        Text(this.authMsg).fontSize(11).fontColor('#B23B3B').margin({ top: 12 })
      }
      Text('接口：' + this.apiRoot())
        .fontSize(10).fontColor('#A79C89').margin({ top: 14 })
    }
    .width('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
    .layoutWeight(1)
  }

  @Builder
  headerBar() {
    Row() {
      Text('青')
        .width(36).height(36).borderRadius(12)
        .backgroundColor('#B8863B').fontColor(Color.White)
        .fontSize(17).fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Center)
      Column() {
        Text('青鸾')
          .fontSize(17).fontWeight(FontWeight.Bold).fontColor('#2B241A').fontFamily('serif')
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 10 })

      Blank()

      Text('设置')
        .fontSize(11).fontColor('#8A5A2B')
        .padding({ left: 10, right: 10, top: 5, bottom: 5 })
        .backgroundColor('#F3E9D2').borderRadius(999)
        .onClick(() => {
          this.formBase = this.llmBase;
          this.formModel = this.llmModel;
          this.formKey = this.llmKey;
          this.testResult = '';
          this.showSet = true;
        })
    }
    .width('100%')
    .padding({ left: 18, right: 18, top: 14, bottom: 10 })
  }

  @Builder
  bubble(m: ChatMsg) {
    Row() {
      if (m.role === 'user') {
        Blank()
      }
      Column() {
        Text(m.text)
          .fontSize(13.5).lineHeight(21)
          .fontColor(m.role === 'user' ? Color.White : (m.role === 'sys' ? '#8C8474' : '#2B241A'))
          .backgroundColor(m.role === 'user' ? '#C08A3E' : (m.role === 'sys' ? '#EFE2C8' : '#FFFAEE'))
          .borderRadius(14)
          .border({ width: m.role === 'user' ? 0 : 1, color: '#DCC49B' })
          .padding({ left: 12, right: 12, top: 9, bottom: 9 })
          .constraintSize({ maxWidth: '78%' })

        if (m.src !== undefined && m.src.length > 0) {
          Text(m.src)
            .fontSize(10).fontColor('#A79C89')
            .margin({ top: 4 })
            .constraintSize({ maxWidth: '86%' })
        }

        if (m.entry !== undefined && m.entry.length > 0) {
          Text('打开知识库 · ' + m.entry + ' →')
            .fontSize(11).fontColor('#8A5A2B')
            .padding({ left: 12, right: 12, top: 7, bottom: 7 })
            .margin({ top: 6 })
            .backgroundColor('#FFF9EE')
            .borderRadius(10)
            .border({ width: 1, color: '#E3CDA4' })
            .onClick(() => {
              const t: string = m.entry as string;
              router.pushUrl({ url: 'pages/detail', params: { title: t } });
            })
        }
      }
      .alignItems(HorizontalAlign.Start)

      if (m.role !== 'user') {
        Blank()
      }
    }
    .width('100%')
  }

  @Builder
  composer() {
    Row() {
      TextInput({ text: $$this.draft, placeholder: '问问黄河的事，或随便聊聊…' })
        .fontSize(13).placeholderColor('#9B9183')
        .backgroundColor('#F7F1E3').borderRadius(11).height(40).layoutWeight(1)
        .onSubmit(() => {
          this.send();
        })
      Button(this.busy ? '…' : '发送')
        .fontSize(12).height(40).width(62)
        .backgroundColor(this.busy ? '#C9B79A' : '#B8863B')
        .fontColor(Color.White).borderRadius(11).margin({ left: 8 })
        .enabled(!this.busy)
        .onClick(() => {
          this.send();
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 10 })
    .backgroundColor('#FFF6E6')
    .border({ width: { top: 1 }, color: '#DCC49B' })
  }

  @Builder
  settingSheet() {
    Column() {
      Text('接口设置')
        .fontSize(16).fontWeight(FontWeight.Bold).fontColor('#2B241A').fontFamily('serif')

      Text('接口地址').fontSize(11).fontColor('#8C8474').margin({ top: 14, bottom: 6 })
      TextInput({ text: this.formBase, placeholder: 'https://api.deepseek.com/v1' })
        .fontSize(12).height(42).backgroundColor('#F7F1E3').borderRadius(11)
        .onChange((v: string) => {
          this.formBase = v;
        })

      Text('模型').fontSize(11).fontColor('#8C8474').margin({ top: 12, bottom: 6 })
      TextInput({ text: this.formModel, placeholder: 'deepseek-flash' })
        .fontSize(12).height(42).backgroundColor('#F7F1E3').borderRadius(11)
        .onChange((v: string) => {
          this.formModel = v;
        })

      Text('API Key').fontSize(11).fontColor('#8C8474').margin({ top: 12, bottom: 6 })
      TextInput({ text: this.formKey, placeholder: 'sk-...' })
        .type(InputType.Password)
        .fontSize(12).height(42).backgroundColor('#F7F1E3').borderRadius(11)
        .onChange((v: string) => {
          this.formKey = v;
        })

      Text('Key 只存在本机，不会上传。留空则纯离线，用内置知识库回答。')
        .fontSize(10).fontColor('#8C8474').lineHeight(16).margin({ top: 10 })

      Row() {
        Button('测试连接')
          .fontSize(13).height(42).layoutWeight(1).borderRadius(11)
          .backgroundColor('#F7F1E3').fontColor('#2B241A')
          .onClick(async () => {
            this.llmBase = this.formBase;
            this.llmModel = this.formModel;
            this.llmKey = this.formKey;
            this.testResult = '测试中…';
            const r: string = await this.callLLM('用一句话说明你是谁');
            this.testResult = r.length > 0 ? ('连接正常：' + r.substring(0, 30)) : '连接失败，检查地址与 Key';
          })
        Button('保存')
          .fontSize(13).height(42).layoutWeight(1).borderRadius(11).margin({ left: 9 })
          .backgroundColor('#B8863B').fontColor(Color.White)
          .onClick(() => {
            this.llmBase = this.formBase;
            this.llmModel = this.formModel;
            this.llmKey = this.formKey;
            this.showSet = false;
            promptAction.showToast({
              message: this.llmKey.length > 0 ? '已启用 ' + this.llmModel : '已切回本地知识库',
              duration: 1500
            });
          })
      }
      .width('100%').margin({ top: 14 })

      if (this.testResult.length > 0) {
        Text(this.testResult)
          .fontSize(11).fontColor('#8A5A2B').margin({ top: 10 })
      }
    }
    .width('100%')
    .padding(20)
    .alignItems(HorizontalAlign.Start)
  }

  build() {
    Column() {
      this.stage()
      this.headerBar()

      List({ space: 10, scroller: this.scroller }) {
        ForEach(this.msgs, (m: ChatMsg) => {
          ListItem() {
            this.bubble(m)
          }
        }, (m: ChatMsg) => m.id.toString())
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .scrollBar(BarState.Off)

      Row() {
        ForEach(['黄河概况', '二里头', '青铜器', '推荐', '时间轴'], (c: string) => {
          Text(c)
            .fontSize(11).fontColor('#8A5A2B')
            .padding({ left: 11, right: 11, top: 6, bottom: 6 })
            .backgroundColor('#F3E9D2').borderRadius(999).margin({ right: 7 })
            .onClick(() => {
              this.send(c);
            })
        }, (c: string) => c)
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 6 })

      this.composer()
    }
    .width('100%')
    .height('100%')
    .linearGradient({ angle: 178, colors: [['#E8D4AE', 0], ['#DEC59C', 0.44], ['#CDB07F', 1]] })
    .bindSheet($$this.showSet, this.settingSheet(), {
      height: 560,
      showClose: true,
      backgroundColor: '#FFFDF8'
    })
  }
}
