export interface UserProfile {
  id: string;
  nickname: string;
  avatar: string;
  inviteCode?: string;
  balance: number;
  totalCoins: number;
  stepTarget: number;
  persistedDays: number;
  consecutiveSignDays: number;
}

export interface StepSnapshot {
  date: string; // yyyy-MM-dd
  steps: number;
  calories: number;
  distanceKm: number;
  durationMinutes: number;
}

export interface SignRecord {
  date: string;
  reward: number;
  completed: boolean;
}

export interface TaskReward {
  id: number;
  title: string;
  description: string;
  reward: number;
  progress: number;
  target: number;
  type: 'step' | 'invite' | 'ad' | 'daily';
  status: 'locked' | 'available' | 'completed' | 'claimed';
}

export interface CoinHistoryItem {
  id: string;
  title: string;
  amount: number;
  type: 'income' | 'expense';
  createdAt: string;
}

export interface AppState {
  user: UserProfile | null;
  todaySnapshot: StepSnapshot | null;
  weeklyTrend: StepSnapshot[];
  signRecords: SignRecord[];
  tasks: TaskReward[];
  coinHistory: CoinHistoryItem[];
}







